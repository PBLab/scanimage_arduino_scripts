function dff_log_session(cfg, resolvedFps, logDir)
    % Writes one reproducibility log record per acqModeStart (CLAUDE.md §3):
    % input params (channel, window, dff_calc params), resolved fps, MATLAB
    % version, and GPU device name.
    if ~exist(logDir, 'dir')
        mkdir(logDir);
    end

    ts = datetime('now');
    record = struct( ...
        'timestamp', char(ts), ...
        'channelIdx', cfg.channelIdx, ...
        'windowSeconds', cfg.windowSeconds, ...
        'dffParams', cfg.dffParams, ...
        'resolvedFps', resolvedFps, ...
        'matlabVersion', version(), ...
        'gpuDevice', local_gpu_device_name()); %#ok<NASGU>

    fname = fullfile(logDir, sprintf('dff_session_%s.mat', char(ts, 'yyyyMMdd_HHmmss')));
    save(fname, 'record');
end

function name = local_gpu_device_name()
    try
        d = gpuDevice();
        name = d.Name;
    catch
        name = 'unavailable';
    end
end
