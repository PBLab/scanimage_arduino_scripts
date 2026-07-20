function dff_on_acq_mode_start(src, evt, varargin) %#ok<INUSD>
    % Thin ScanImage-facing callback for the acqModeStart event. Dispatches to
    % the live RealtimeDffMonitor singleton via dff_monitor_instance.
    mon = dff_monitor_instance('get');
    if isempty(mon)
        warning('dff_on_frame_acquired:noMonitor', ...
            'No RealtimeDffMonitor instance found. Setting it.');
        evalin('base','dff_realtime_init(hSI)');
    end
    mon.onAcqModeStart(src, evt);
end
