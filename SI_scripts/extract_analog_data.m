function extract_analog_data(src,evt,varargin)
    % This functions allows the user to utilize unused imaging channels to 
    % record analog data. 
    % It is currenlty configured to record two different signals, namely air
    % puffs and mouse running, into two "imaging inputs" of the FlexRIO. The
    % current default channels are 1 for the puff data, and 3 for the run data.
    %
    % It does so by creating an Nx2 matrix, where N is the number of expected
    % frames in the imaging session, and populating it with the minimal value of
    % the "image" displayed in these analog channels after each acquired
    % frame. This helps us to detect the momemnt in which a puff, or the
    % start of the mouse's movement, occurred.
    
    % The first column of the data is the puff channel data, while the second
    % is the running data. Finally, when the acquisition is done (or
    % aborted), the data is written to disk with the suffix "_analog.txt".
    persistent analog_data_buffer
    persistent analog_file_name
    %clc
    hSI = src.hSI;

    % Constant values - should be changed with care!
    PUFF_DATA_CHANNEL = 4;  
    RUN_DATA_CHANNEL = 3;
    FRAME_DELAY_OF_RUN_CHANNEL = -0.7667;  % seconds

    switch evt.EventName
        case {'acqModeStart'}
            % Generate analog data file path and buffer
            analog_data_buffer = zeros(hSI.hStackManager.framesPerSlice, 2);
            analog_file_name = hSI.hScan2D.logFileStem;
            if hSI.hScan2D.logFilePath
                file_path = hSI.hScan2D.logFilePath;
            else
                file_path = 'E:\';
            end
            counter = hSI.hScan2D.logFileCounter;
            analog_file_name = fullfile(file_path,sprintf('%s_%05d_analog.txt',analog_file_name,counter));
            % Check that all four needed channels are active
            if numel(hSI.hChannels.channelDisplay) < 4
               hSI.errorMsg = 'Analog data acquisition is enabled. Make sure that all four channels are displayed.';
            end
        case {'frameAcquired'}
            min_puff = min(hSI.hDisplay.lastFrame{PUFF_DATA_CHANNEL}(:));
            mean_run = mean(hSI.hDisplay.lastFrame{RUN_DATA_CHANNEL}(:));
            analog_data_buffer(hSI.hDisplay.lastFrameNumber, :) = [min_puff, mean_run];

        case {'acqAbort', 'acqDone'}
            if hSI.hChannels.loggingEnable
                disp('Writing analog data to disk')
                % Shift the run data due to delay between actual running time
                % and the time the data arrives at the analog input
                delay_in_frames = ceil(FRAME_DELAY_OF_RUN_CHANNEL * hSI.hRoiManager.scanFrameRate);
                analog_data_buffer(:, 2) = circshift(analog_data_buffer(:, 2), delay_in_frames);
                analog_data_buffer(end + uint16(delay_in_frames) - 1:end, 2) = 0;  % account for circularity of shift
                csvwrite(analog_file_name, analog_data_buffer);
            end

    end

end