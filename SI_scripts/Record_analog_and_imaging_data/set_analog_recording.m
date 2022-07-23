function set_analog_recording(analog_channels)

fprintf('\n Setting up acquisition session...')
evalin('base','if exist(''dq'');delete(dq);end')

cmd = 'dq = daq.createSession("ni");';

for ch_i = analog_channels
    %we assume all channels recording are of typte "voltage" - this can be
    %modified in the future to include counters or digital channels.
    cmd = strcat(cmd,sprintf('dq.addAnalogInputChannel(''Dev1'', ''ai%d'', ''Voltage'');',ch_i));
end

%cmd =  strcat(cmd,'dq.addAnalogInputChannel(''Dev1'', ''ai6'', ''Voltage'');');
cmd =  strcat(cmd, 'dq.IsContinuous=true;');

%%
cmd =  strcat(cmd,'fid = fopen(''log.csv'',''w'');');
cmd = strcat(cmd, 'lh = dq.addlistener(''DataAvailable'',@(src,event)saveData(fid,event));');
evalin('base',cmd);
evalin('base','disp(dq);');