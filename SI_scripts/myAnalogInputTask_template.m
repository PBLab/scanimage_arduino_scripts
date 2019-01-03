function myAnalogInputTask(src,evt)
persistent hTask

deviceName = 'PXI1Slot4';
channels = 0:3;
sampleRate = 1000; % [Hz]
everyNSamples = 1000;

hSI = src.hSI;
switch evt.EventName
    case {'focusStart' 'acqModeStart'}
        most.idioms.safeDeleteObj(hTask);
        hTask = most.util.safeCreateTask('My Analog Input Task');
        hTask.createAIVoltageChan(deviceName,channels);
        hTask.cfgSampClkTiming(sampleRate,'DAQmx_Val_ContSamps');
        
        set(hTask,'sampClkTimebaseRate',10e6);
        set(hTask,'sampClkTimebaseSrc',['/' deviceName '/PXI_Clk10']);
        
        assert(hTask.sampClkRate == sampleRate,'Requested sample rate could not be satisfied');
        
        hTask.cfgDigEdgeStartTrig(hSI.hScan2D.hTrig.frameClockOut);
        hTask.registerEveryNSamplesEvent(@myCallback,everyNSamples,true);
        hTask.start();
    case {'acqModeDone','acqAbort','focusDone'}
        most.idioms.safeDeleteObj(hTask);
end
    
end

function myCallback(src,evt)    
    persistent hAx
    
    if isempty(hAx) || ~isvalid(hAx)
        hFig = figure();
        hAx = axes('Parent',hFig);
    end
    
    plot(hAx,evt.data);
    
end