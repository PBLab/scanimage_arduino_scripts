function stop_analog_recording(src,event,varargin)
%% script to stop analog recording. expects to have an object called dq
cmd = 'dq.stop;delete(dq);';
evalin('base',cmd)