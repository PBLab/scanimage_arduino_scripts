function si_register_user_functions(hSI, status) %#ok<INUSD>
% Adapter: registers callbacks against hSI.hUserFunctions.
% Updated by PB

%% ensure user functions are enabled.
func_names = {'dff_on_acq_mode_start','dff_on_acq_mode_start','dff_on_frame_acquired',...
    'dff_realtime_cleanup','dff_realtime_cleanup','dff_realtime_cleanup'};
event_names = {'focusStart','acqModeStart','frameAcquired','acqDone','focusDone','acqAbort'};
arguments ={{},{},{},{},{},{}};
enable_on = {1,1,1,1,1,1};
enable_off = {0,0,0,0,0,0};
user_func_on = struct('EventName',event_names,'UserFcnName',func_names,'Arguments',arguments,'Enable',enable_on);
user_func_off= struct('EventName',event_names,'UserFcnName',func_names,'Arguments',arguments,'Enable',enable_off);

switch status
    case 'on'
        hSI.hUserFunctions.userFunctionsCfg = user_func_on;
    case 'off'
        hSI.hUserFunctions.userFunctionsCfg = user_func_off;
    otherwise
        error("status argument must be 'on' or 'off'")
end
end
