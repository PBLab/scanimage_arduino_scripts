function stop_analog_recording(src,event,varargin)
%% script to stop analog recording. expects to have an object called dq
evalin('base','dq.stop;')