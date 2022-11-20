%analyze neuronal calcium data and ECG


%% define parameters

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
HR_sample_window_sec = 1;
analog_samples_per_sec = 1000;
HR_sample_window_samples = HR_sample_window_sec*analog_samples_per_sec;
HR_BPM_conv_factor_sec = 60/HR_sample_window_sec;

%% load ECG and crop if needed - there are three columns in the file: time (ms), ECG and TTL (frame_start +5V)
T = readtable(fullfile(path_src_dir,fname_ecg));
T.Properties.VariableNames={'Time','ECG','TTL'};
%% crop data between beginning of first frame and end of last frame
first_frame_t_sec = find(T.TTL>ttl_vol_thresh,1,'first');
last_frame_t_sec = find(T.TTL>ttl_vol_thresh,1,'last');

T = T(first_frame_t_sec:last_frame_t_sec,:);
T.Time = T.Time - T.Time(1);


%% build look up table between ECG and frame number as neuronal data is sampled on a frame basis
%binarize ttl signal
ttl = T.TTL>4; %point after zero-value is new frame, starts high
frame_stops = find(ttl==0);
t_frame_stops = T.Time(frame_stops);
n_frames = numel(frame_stops);
figure    
plot(T.Time,ttl,'rs',T.Time,T.TTL,'k-')
xlim([1198,1201])
%% Find ECG components (based on https://www.mathworks.com/help/signal/ug/peak-analysis.html)

% %R-component
% [~,locs_Rwave] = findpeaks(T.ECG,'MinPeakHeight',ecg_R_vol_thresh,...
%     'MinPeakDistance',100);
% %S-component is min ECG
% [~,locs_Swave] = findpeaks(-T.ECG,'MinPeakHeight',0.5,...
%     'MinPeakDistance',100);

[locs_Rwave] = find_R_peaks(T.ECG,ecg_R_vol_thresh,mean_peak_dist);

figure('windowStyle','Docked')
hold on
plot(T.Time,T.ECG)
plot(T.Time(locs_Rwave),T.ECG(locs_Rwave),'rv','MarkerFaceColor','r')
%plot(T.Time(locs_Swave),T.ECG(locs_Swave),'rs','MarkerFaceColor','b')
plot(T.Time,T.TTL)
grid on

RR_int = diff(T.Time(locs_Rwave));
figure('windowStyle','Docked');histogram(RR_int,'Normalization','probability')
xlim([0.1 0.15])
xlabel('RR interval (s)')


%% Compute instantaneous HR 
T.Rpeak = zeros(size(T,1),1);
T.Rpeak(locs_Rwave)=1;
bpm = movsum(T.Rpeak,HR_sample_window_samples)*HR_BPM_conv_factor_sec;
yyaxis left
hold on
plot(T.Time,T.ECG)
plot(T.Time(locs_Rwave),T.ECG(locs_Rwave),'rv','MarkerFaceColor','r')

yyaxis right
plot(T.Time,bpm)

%% load dff data stored in the hd5f file under estimates/F_dff
clc
path_to_h5 = fullfile(path_src_dir,fname_hd5);
h5disp(path_to_h5,'/estimates/F_dff');
F_dff = h5read(path_to_h5,hd5_dff_data);
[n_frames,n_neurons] = size(F_dff);
t_sec = linspace(0,T.Time(end),n_frames);

%% create a raster matrix of infered spike times (this should be done by the CASCADE algorithm).
% SPIKES = table('Size',[34 3],...
%     'VariableTypes',{'single','cell','cell'},...
%     'VariableNames',{'neuron_id','spike_loc', 'spike_times_s'});
%
%
% for neuron_i = 1 : n_neurons
%     [~,loc] = findpeaks(F_dff(:,neuron_i),'MinPeakProminence',1);
%     SPIKES.neuron_id(neuron_i) = neuron_i;
%     SPIKES.spike_loc{neuron_i} = loc;
%     SPIKES.spike_times_s{neuron_i} = T.Time(loc);
% end

SPIKES = sparse(n_frames,n_neurons);
for neuron_i = 1 : n_neurons
    [~,loc] = findpeaks(F_dff(:,neuron_i),'MinPeakProminence',0.5);
    n_loc = size(loc);
    SPIKES(loc,neuron_i) = 1;
end
imagesc(SPIKES)
colormap(copper)
axis tight

%% construct a PSTH (where stimulus is a heart beat)
%for each beat, build an index sampling matrix to query spikes or dff data, take n frames
%around each event
n_beats = numel(locs_Rwave);
idx = -floor(psth_n_frames/2):floor(psth_n_frames/2);
idx = (repmat(idx,n_beats,1)+locs_Rwave)';
idx = idx(:);

neuron_i = 1
this_neuron_spikes = full(SPIKES(idx(1:end),neuron_i));


