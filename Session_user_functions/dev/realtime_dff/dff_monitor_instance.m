function obj = dff_monitor_instance(action, varargin)
    % Single point of truth for the live RealtimeDffMonitor singleton.
    % ScanImage calls named top-level functions (not object methods), so this
    % persistent-variable accessor is how monitor state survives across calls.
    %
    % action: 'get'    -> returns the current instance, or [] if none exists
    %         'create' -> varargin = {hSI, cfg}; constructs and stores a new instance
    %         'clear'  -> discards the current instance; returns []
    persistent monitorObj

    switch action
        case 'get'
            obj = monitorObj;
        case 'create'
            monitorObj = RealtimeDffMonitor(varargin{1}, varargin{2});
            obj = monitorObj;
            obj.Reset
        case 'clear'
            monitorObj = [];
            obj = [];
        otherwise
            error('dff_monitor_instance:invalidAction', 'Unknown action "%s".', action);
    end
end
