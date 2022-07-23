function testSliceTime(src, evt, varargin)

    persistent sliceCount;
    persistent profileWasOn;
    persistent acqStartToSliceDoneTime;
    persistent sliceDoneToNextAqcStart;
    
    if isempty(sliceCount)
       sliceCount = 0; 
    end
    
    if isempty(profileWasOn)
        profileWasOn = false;
    end
    
    if isempty(acqStartToSliceDoneTime)
       acqStartToSliceDoneTime = uint64(0); 
    end
    
    if isempty(sliceDoneToNextAqcStart)
       sliceDoneToNextAqcStart = uint64(0); 
    end
    
    switch evt.EventName
        case 'sliceDone'
            disp('Slice Done')
            disp('Acq Start to Slice Done');
            toc(acqStartToSliceDoneTime);
            sliceDoneToNextAqcStart = tic;
            sliceCount = sliceCount + 1;
            profile on;
            profileWasOn = true;
        case 'acqStart'
            disp('Acquisition Started')
            disp('Slice done to next Acq start');
            toc(sliceDoneToNextAqcStart);
            acqStartToSliceDoneTime = tic;
            if profileWasOn
               profile off;
               profileWasOn = false;
               profileInfo = profile('info');
               save(sprintf('Slice_%d_profile.mat', sliceCount), 'profileInfo', '-v6');
            end
            
        case 'acqDone'
            sliceCount = 0;
            profileWasOn = false;
            sliceDoneToNextAqcStart = uint64(0);
            acqStartToSliceDoneTime = uint64(0);
    end
    
end