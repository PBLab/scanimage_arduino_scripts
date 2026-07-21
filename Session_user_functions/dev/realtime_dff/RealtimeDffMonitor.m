classdef RealtimeDffMonitor < handle
    % Owns the GPU-resident frame/trace buffers for one ScanImage acquisition and
    % orchestrates whole-FOV trace extraction, dff_calc.m, and live plot updates
    % per frameAcquired/acqModeStart event. See tasks/design_realtime_dff.md.

    properties
        hSI              % ScanImage model reference (not owned)
        ChannelIdx        % functional channel index
        WindowSeconds     % configured buffer time window (s)
        Fps               % resolved at acqModeStart
        WindowSamples     % round(WindowSeconds * Fps)
        DffParams         % struct: tau_0, tau_1, tau_2, invert
        LogDir            % directory for per-session reproducibility logs
        FrameBuffer       % gpuArray [H, W, WindowSamples], class matches live frame; [] until first frame
        TraceBuffer       % gpuArray [WindowSamples, 1] double; per-frame whole-FOV means
        WritePtr          % circular write index, 0-based before mod
        NFilled           % samples written so far, capped at WindowSamples
        Viewer            % DffLiveViewer instance
    end

    methods
        function obj = RealtimeDffMonitor(hSI, cfg)
            obj.hSI = hSI;
            obj.ChannelIdx = cfg.channelIdx;
            obj.WindowSeconds = cfg.windowSeconds;
            obj.DffParams = cfg.dffParams;
            obj.LogDir = cfg.logDir;
            obj.FrameBuffer = [];
            obj.TraceBuffer = [];
            obj.WritePtr = 0;
            obj.NFilled = 0;
            obj.Viewer = [];
        end

        function Reset(obj)
            %function used to initialize object or reset during focus (grab
            %moded triggers the onAcqModeStart
                        % FR1, FR2: (re)allocate buffer sizing and reset/open the live plot.
            % Any prior buffer content is discarded — never reused across acq modes.
            obj.Fps = si_get_frame_rate(obj.hSI);
            obj.WindowSamples = round(obj.WindowSeconds * obj.Fps);

            % Prepare buffers, get img size from ROI manager
            %
            h = obj.hSI.hRoiManager.linesPerFrame;
            w = obj.hSI.hRoiManager.pixelsPerLine;
            obj.FrameBuffer = zeros(h, w, obj.WindowSamples, 'gpuArray');
            obj.TraceBuffer = zeros(obj.WindowSamples, 1,'gpuArray'); %Modify to keep either trace of dff image or set of traces for defined ROIs
            obj.WritePtr = 0;
            obj.NFilled = 0;
            if isempty(obj.Viewer) || ~isvalid(obj.Viewer)
                obj.Viewer = DffLiveViewer();
            else
                obj.Viewer.reset();
            end

        end
        
        function onAcqModeStart(obj, src, evt) %#ok<INUSD>
            fprintf('---------------------------- AcqModStart -----------------------\n')
            obj.Reset
            cfg = struct('channelIdx', obj.ChannelIdx, 'windowSeconds', obj.WindowSeconds, ...
                'dffParams', obj.DffParams);
            dff_log_session(cfg, obj.Fps, obj.LogDir);
        end

        function onFrameAcquired(obj, src, evt) %#ok<INUSD>
            % FR3, FR4: push the newest frame into the circular buffers, recompute
            % df/f over the full ordered trace, and update the live plot.
            frame = si_get_last_frame(obj.hSI, obj.ChannelIdx);

            idx = obj.WritePtr + 1;
            obj.FrameBuffer(:, :, idx) = gpuArray(frame);
            obj.TraceBuffer(idx) = mean(double(frame(:)));

            obj.WritePtr = mod(idx, obj.WindowSamples);
            obj.NFilled = min(obj.NFilled + 1, obj.WindowSamples);

            %DFF calculation should be either on the entire image OR on mean
            %pixel values from defined ROIs
            trace = obj.orderedTrace();
            dff = dff_calc(trace, obj.Fps, obj.DffParams.tau_0, obj.DffParams.tau_1, ...
                obj.DffParams.tau_2, obj.DffParams.invert);

            tSec = (0:obj.NFilled - 1)' / obj.Fps;
            obj.Viewer.update(frame,tSec, dff);
        end

        function trace = currentTrace(obj)
            % Read-only accessor for the current chronologically-ordered trace.
            % Exposed for inspection/testing; not used internally.
            trace = obj.orderedTrace();
        end
    end

    methods (Access = private)
        function trace = orderedTrace(obj)
            % Returns TraceBuffer reordered oldest->newest for dff_calc.
            % See tasks/design_realtime_dff.md §7 for the derivation.
            if obj.NFilled < obj.WindowSamples
                trace = obj.TraceBuffer(1:obj.NFilled);
            else
                trace = [obj.TraceBuffer(obj.WritePtr + 1:end); obj.TraceBuffer(1:obj.WritePtr)];
            end
        end
    end
end
