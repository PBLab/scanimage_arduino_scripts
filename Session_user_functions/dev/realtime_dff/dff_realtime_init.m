function dff_realtime_init(hSI, cfgOverrides)
    % Public entry point: call once per ScanImage session to construct the
    % monitor singleton and register its callbacks against hSI.hUserFunctions.
    %
    % cfgOverrides (optional): struct with any of dff_default_params()'s fields
    % to override (channelIdx, windowSeconds, dffParams, logDir). Shallow merge —
    % overriding dffParams replaces the whole tau_0/tau_1/tau_2/invert struct.
    if nargin < 2
        cfgOverrides = struct();
    end

    cfg = dff_default_params();
    overrideFields = fieldnames(cfgOverrides);
    for i = 1:numel(overrideFields)
        cfg.(overrideFields{i}) = cfgOverrides.(overrideFields{i});
    end

    dff_monitor_instance('create', hSI, cfg); % Monitor object is declared as persistent in this function 
    si_register_user_functions(hSI, 'on');

end
