%analyze ECG last recorded data
analog_file_name = 'fov_1_mag_2p2_512px_30hz_#2_baseline_00001_analog.csv';

%% define parameters
ttl_vol_thresh = 3; %TTL is 5 so this seems failry robust
ecg_R_vol_thresh = 2;
mean_peak_dist = 60;
psth_n_frames = 5;

todo_crop_ecg = 1;
todo_find_ecg_peaks = 1;
todo_detrend_ECG = 0;

HR_sample_window_sec = 10;
analog_samples_per_sec = 1000;
HR_sample_window_samples = HR_sample_window_sec*analog_samples_per_sec;
HR_BPM_conv_factor_sec = 60/HR_sample_window_sec;

%% load ECG and crop if needed - there are three columns in the file: time (ms), ECG and TTL (frame_start +5V)
[~,fname]=fileparts(analog_file_name);
T = readtable(analog_file_name);
T.Properties.VariableNames={'Time','ECG','TTL'};
%% crop data between beginning of first frame and end of last frame
first_frame_t_sec = find(T.TTL>ttl_vol_thresh,1,'first');
last_frame_t_sec = find(T.TTL>ttl_vol_thresh,1,'last');

T = T(first_frame_t_sec:last_frame_t_sec,:);
T.Time = T.Time - T.Time(1);

%% Find ECG components (based on https://www.mathworks.com/help/signal/ug/peak-analysis.html)

[locs_Rwave] = find_R_peaks(T.ECG,ecg_R_vol_thresh,mean_peak_dist);
% 
% figure('windowStyle','Docked')
% hold on
% plot(T.Time,T.ECG)
% plot(T.Time(locs_Rwave),T.ECG(locs_Rwave),'rv','MarkerFaceColor','r')
% grid on

%% Compute instantaneous HR 
T.Rpeak = zeros(size(T,1),1);
T.Rpeak(locs_Rwave)=1;
bpm = movsum(T.Rpeak,HR_sample_window_samples)*HR_BPM_conv_factor_sec;

%plot 
figure('Name',['ECG - ' fname],'units','norm','pos',[0.3131    0.2201    0.6369    0.7083]);
subplot(2,1,1)
yyaxis left
hold on
plot(T.Time,T.ECG)
plot(T.Time(locs_Rwave),T.ECG(locs_Rwave),'rv','MarkerFaceColor','r')
ylabel('ECG (V)');
xlabel('Time (s)');

yyaxis right
plot(T.Time,bpm)
ylabel('Heart rapte (bpm)')

%%
% RR_int = diff(T.Time(locs_Rwave));
% figure('windowStyle','Docked');histogram(RR_int,'Normalization','probability')
% xlim([0.1 0.15])
% xlabel('RR interval (s)')

