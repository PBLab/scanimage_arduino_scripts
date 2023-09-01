function stop_analog_recording(src,event,varargin)
%% script to stop analog recording. expects to have an object called dq
evalin('base','dq.stop;')
evalin('base','fclose all')
evalin('base','hSI.hUserFunctions.userFunctionsCfg = user_func_off;');
%trigger display of last acquisition
evalin('base','display_last_analog_acq(analog_file_name)')
disp('Done')