function dff_realtime_cleanup(src,event,varargin)
%clean up variables from gpu
disp('Cleaning up')
mon = dff_monitor_instance('get');
if ~isempty(mon)
    mon.onAcqDone(src, event);
end