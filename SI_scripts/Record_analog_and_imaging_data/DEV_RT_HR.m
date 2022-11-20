% demo environment for HR estimating from analog recordings

% load some data to play.
%files
path_src_dir = '/Users/pb/Dropbox/__DATA2/GCaMP_ECG';
fname_ecg = 'fov1_mag_1_512px_30hz_00001_analog.csv';
fname_hd5 = 'fov1_mag_1_512px_30hz_00001.tif #1_memmap__d1_512_d2_512_d3_1_order_C_frames_36000_.hdf5';
hd5_dff_data = '/estimates/F_dff';

%paramteres
ttl_vol_thresh = 4.5; %TTL is 5 so this seems failry robust
ecg_R_vol_thresh = 4;
mean_peak_dist = 100;
psth_n_frames = 5;

todo_crop_ecg = 1;
todo_find_ecg_peaks = 1;
todo_detrend_ECG = 0;

%%
HR_sample_window_sec = 2.5;
analog_samples_per_sec = 1000;
HR_sample_window_samples = HR_sample_window_sec*analog_samples_per_sec;
HR_BPM_conv_factor_sec = 60/HR_sample_window_sec;

%% load ECG and crop if needed - there are three columns in the file: time (ms), ECG and TTL (frame_start +5V)
T = readtable(fullfile(path_src_dir,fname_ecg));
T.Properties.VariableNames={'Time','ECG','TTL'};

%% Populate buffer with 100samples every 100m
samples_per_chunk = 100;
data_len = size(T.ECG,1)

global analog_buffer
global hr_history
analog_buffer = zeros (HR_sample_window_samples,1);
hr_history = [];

data_chunk_idx = 1:samples_per_chunk;
figure('windowstyle','docked','Name','Analog data stream')
a1=subplot(2,1,1);
a2=subplot(2,1,2);


for k = 1 : data_len
    pause(0.1)
    data_from_event = T.ECG(data_chunk_idx);
    
    % add to buffer
    analog_buffer = [analog_buffer(samples_per_chunk+1:end) ;data_from_event];
    plot(a1,analog_buffer);drawnow
    %compute hr
    [locs_Rwave] = find_R_peaks(analog_buffer,ecg_R_vol_thresh,mean_peak_dist);
    hr = numel(locs_Rwave)*HR_BPM_conv_factor_sec;
    hr_history = [hr_history;hr];
    plot(a2,hr_history);
    
    data_chunk_idx = data_chunk_idx + samples_per_chunk;
    
    
end



