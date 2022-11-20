function set_analog_recording(hSI,analog_channels)

fprintf('\n Setting up acquisition session...')


 % Generate analog data file path and buffer
 analog_file_name = hSI.hScan2D.logFileStem;
 if hSI.hScan2D.logFilePath
     file_path = hSI.hScan2D.logFilePath;
 else
     file_path = 'E:\';
 end
 counter = hSI.hScan2D.logFileCounter;
 analog_file_name = fullfile(file_path,sprintf('%s_%05d_analog.csv',analog_file_name,counter));
 assignin('base','analog_file_name',analog_file_name);%store for later use 

%set up daq session
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
cmd =  strcat(cmd,sprintf('fid = fopen(''%s'',''w'');',analog_file_name));
cmd = strcat(cmd, 'lh = dq.addlistener(''DataAvailable'',@(src,event)saveData(fid,event));');
cmd = strcat(cmd, 'lh2 = dq.addlistener(''DataAvailable'',@(src,event)plotData(event));');
evalin('base',cmd);
evalin('base','disp(dq);');