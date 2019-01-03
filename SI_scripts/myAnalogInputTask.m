function myAnalogInputTask(src,evt,varargin)
persistent hTask 
persistent file_name
persistent file_path
global ptr2file

clc
disp('Started analog data acq')
deviceName = 'Dev1';
channels = [0,7];
sampleRate = 1000; % [Hz]
everyNSamples = 1000;
hSI = src.hSI;
switch evt.EventName
    case {'focusStart' 'acqModeStart'}
        %clean up previous values (from AcqStart etc)
        most.idioms.safeDeleteObj(hTask);
        file_name = [];
        file_path =[];
        
        hTask = most.util.safeCreateTask('My Analog Input Task');
        hTask.createAIVoltageChan(deviceName,channels);
        hTask.cfgSampClkTiming(sampleRate,'DAQmx_Val_ContSamps');
        
        
        %set(hTask,'sampClkTimebaseRate',10e6);
        %set(hTask,'sampClkTimebaseSrc',['/' deviceName '/PXI_Clk10']); not
        %supported in USB NI
        
        assert(hTask.sampClkRate == sampleRate,'Requested sample rate could not be satisfied');
        
        %hTask.cfgDigEdgeStartTrig(hSI.hScan2D.hTrig.frameClockOut);
        hTask.registerEveryNSamplesEvent(@myCallback,everyNSamples,true);
        hTask.start();
        
        file_name = hSI.hScan2D.logFileStem;
        file_path = hSI.hScan2D.logFilePath;
        counter = hSI.hScan2D.logFileCounter;
        file_name = fullfile(file_path,sprintf('%s_%05d_analog.txt',file_name,counter));
        ptr2file = fopen(file_name,'w+');
        
    case {'acqModeDone','acqAbort','focusDone'}
        disp('Cleaning up')
        most.idioms.safeDeleteObj(hTask);
        
end
    
end

function myCallback(src,evt)    
    persistent hAx
    global ptr2file

    
    if isempty(hAx) || ~isvalid(hAx)
        hFig = figure();
        hAx = axes('Parent',hFig);
    end
    
    plot(hAx,evt.data);
    fprintf(ptr2file,'%f\t%f\n',evt.data');
    
end