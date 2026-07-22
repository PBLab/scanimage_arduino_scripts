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
        WritePtr          % circular write index, 0-based before mod
        NFilled           % samples written so far, capped at WindowSamples
        Viewer            % DffLiveViewer instance
        RoiMasks          % struct array (Label, Color, Position, PixelIdx), one per drawn ROI; empty -> whole-FOV
        LastDffImage      % gpuArray [H, W] double; most recent per-pixel df/f frame (inspection/testing)
        LastTraceMatrix   % gpuArray [WindowSamples, NTraces] double; most recent whole-FOV/ROI trace(s)
    end

    methods
        function obj = RealtimeDffMonitor(hSI, cfg)
            obj.hSI = hSI;
            obj.ChannelIdx = cfg.channelIdx;
            obj.WindowSeconds = cfg.windowSeconds;
            obj.DffParams = cfg.dffParams;
            obj.LogDir = cfg.logDir;
            obj.FrameBuffer = [];
            obj.WritePtr = 0;
            obj.NFilled = 0;
            obj.Viewer = [];
            obj.RoiMasks = [];
            obj.LastDffImage = [];
            obj.LastTraceMatrix = [];
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
            obj.FrameBuffer = [];
            obj.FrameBuffer = zeros(h, w, obj.WindowSamples, 'gpuArray');

            % Viewer must exist (with a live Axes_img) before we scan it for ROIs.
            if isempty(obj.Viewer) || ~isvalid(obj.Viewer)
                obj.Viewer = DffLiveViewer();
            else
                obj.Viewer.reset();
            end

            % FR: df/f is computed on the entire image, OR on the set of ROIs
            % drawn on the viewer (whichever is present) — masks are computed
            % once here and frozen for the whole acquisition (see lockRois()).
            obj.RoiMasks = obj.buildRoiMasks(h, w);
            if isempty(obj.RoiMasks)
                obj.Viewer.setTraces({'whole FOV'}, [0 0.4470 0.7410]);
            else
                obj.Viewer.setTraces({obj.RoiMasks.Label}, cat(1, obj.RoiMasks.Color));
            end

            obj.WritePtr = 0;
            obj.NFilled = 0;
            obj.LastDffImage = [];
            obj.LastTraceMatrix = [];
        end
        
        function onAcqModeStart(obj, src, evt) %#ok<INUSD>
            fprintf('---------------------------- Focus/AcqMod Start -----------------------\n')
            disp(obj.hSI.acqState)
            obj.Reset
            cfg = struct('channelIdx', obj.ChannelIdx, 'windowSeconds', obj.WindowSeconds, ...
                'dffParams', obj.DffParams, 'roiSet', obj.roiSetSummary());
            dff_log_session(cfg, obj.Fps, obj.LogDir);
            obj.Viewer.lockRois();
            drawnow limitrate 
        end

        function onFrameAcquired(obj, src, evt) %#ok<INUSD>
            % Push the newest frame into the circular raw-frame buffer, then compute
            % df/f on the entire image: reshape the ordered (old->new) frame buffer
            % into a [time x pixels] matrix, run dff_calc once, and derive both the
            % displayed df/f image (most recent frame) and the whole-FOV/ROI traces
            % (spatial means) from that single per-pixel result.
            frame = si_get_last_frame(obj.hSI, obj.ChannelIdx);

            idx = obj.WritePtr + 1;
            obj.FrameBuffer(:, :, idx) = gpuArray(frame);

            obj.WritePtr = mod(idx, obj.WindowSamples);
            obj.NFilled = min(obj.NFilled + 1, obj.WindowSamples);

            % Reorder oldest->newest. Not yet wrapped: 1:NFilled is already old->new,
            % nothing to shift. Wrapped: a single circshift reorders in one pass
            % (vs. slicing two chunks + cat, which allocates each slice separately).
            if obj.NFilled < obj.WindowSamples
                framesOrdered = obj.FrameBuffer(:, :, 1:obj.NFilled);
            else
                framesOrdered = circshift(obj.FrameBuffer, -obj.WritePtr, 3);
            end

            [h, w, n] = size(framesOrdered);
            pixelTraces = reshape(double(framesOrdered), h * w, n).';   % N x (H*W), time x pixels

            pixelDff = dff_calc(pixelTraces, obj.Fps, obj.DffParams.tau_0, obj.DffParams.tau_1, ...
                obj.DffParams.tau_2, obj.DffParams.invert);              % N x (H*W)

            dffImage = reshape(pixelDff(end, :), h, w);

            if isempty(obj.RoiMasks)
                traceMatrix = mean(pixelDff, 2);
            else
                traceMatrix = zeros(n, numel(obj.RoiMasks), 'like', pixelDff);
                for i = 1:numel(obj.RoiMasks)
                    traceMatrix(:, i) = mean(pixelDff(:, obj.RoiMasks(i).PixelIdx), 2);
                end
            end

            obj.LastDffImage = dffImage;
            obj.LastTraceMatrix = traceMatrix;

            tSec = (0:obj.NFilled - 1)' / obj.Fps;
            obj.Viewer.update(dffImage, tSec, traceMatrix);
        end

        function onAcqDone(obj, src, evt) %#ok<INUSD>
            % Unfreeze ROI editing now that the acquisition has stopped.
            if ~isempty(obj.Viewer) && isvalid(obj.Viewer)
                obj.Viewer.unlockRois();
                drawnow limitrate
            end
        end

        function trace = currentTrace(obj)
            % Read-only accessor for the most recent whole-FOV/ROI trace(s).
            % Exposed for inspection/testing; not used internally.
            trace = obj.LastTraceMatrix;
        end
    end

    methods (Access = private)
        function masks = buildRoiMasks(obj, h, w)
            % Scans the viewer's image axes for polygon ROIs (Tag == 'ROI') and
            % converts each to a cached pixel-index mask via poly2mask, matching
            % the convention used by Session_analysis/app/Utils/extract_traces.m.
            % Called once per Reset() (acqModeStart) — never per-frame.
            rois = findobj(obj.Viewer.Axes_img, 'Tag', 'ROI');
            masks = struct('Label', {}, 'Color', {}, 'Position', {}, 'PixelIdx', {});
            for i = 1:numel(rois)
                v = rois(i).Position;
                mask = poly2mask(v(:, 1), v(:, 2), h, w);
                masks(i).Label = rois(i).Label;
                masks(i).Color = rois(i).Color;
                masks(i).Position = v;
                masks(i).PixelIdx = find(mask);
            end
        end

        function s = roiSetSummary(obj)
            % Reproducibility-log payload (CLAUDE.md §3): what was actually
            % measured this run, not just the tau/window parameters.
            if isempty(obj.RoiMasks)
                s = 'whole-FOV';
            else
                s = struct('Label', {obj.RoiMasks.Label}, 'Position', {obj.RoiMasks.Position}, ...
                    'Color', {obj.RoiMasks.Color});
            end
        end
    end
end
