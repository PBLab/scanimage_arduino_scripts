function cfg = dff_default_params()
    % Returns the default configuration struct for the real-time df/f monitor.
    % tau/invert values intentionally mirror dff_calc.m's own nargin<N defaults
    % (Session_analysis/app/Proc/dff_calc.m) — duplicated, not introspected; see
    % design doc tasks/design_realtime_dff.md §8 risk 2 for the drift risk this carries.
    cfg = struct();
    cfg.channelIdx = 1;
    cfg.windowSeconds = 2;
    cfg.dffParams = struct('tau_0', 0.1, 'tau_1', 0.35, 'tau_2', 2.0, 'invert', false);

    % Default log dir is computed relative to this file's own location (one level
    % up from wherever this file currently lives) so it keeps working unchanged
    % whether this is still under dev/realtime_dff/ or has been promoted to utils/.
    thisDir = fileparts(mfilename('fullpath'));
    cfg.logDir = fullfile(fileparts(thisDir), 'logs');
end
