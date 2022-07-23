function start_analog_recording(~,~)
%% stub for staring analog acquisition, commands executed in base workspace.
%pause(0.05)
evalin('base','dq.startBackground();');
