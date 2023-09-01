function display_last_analog_acq(analog_file_name)
%function loads and display the last bit of acquired analog data
global ecg_R_vol_thresh
global mean_peak_dist
global HR_BPM_conv_factor_sec
global analog_samples_per_sec

%%
data = readtable(analog_file_name);
data.Properties.VariableNames={'Time','ECG','TTL','AirPuff'};
%% compute HR
R_peaks = zeros(numel(data.Time),1);
[locs_Rwave] = find_R_peaks(data.ECG,ecg_R_vol_thresh,mean_peak_dist);
R_peaks(locs_Rwave)=1;

hr = movsum(R_peaks,analog_samples_per_sec)*HR_BPM_conv_factor_sec;
%% prepare graph output
[~,f_name] = fileparts(analog_file_name);
f1 = figure('windowstyle','docked','Name',f_name)
ax1=subplot(5,1,[1 2]);
h2_line1 = plot(data.Time,data.ECG);
hold on
h2_line1_1 = plot(data.Time(locs_Rwave),data.ECG(locs_Rwave),'r*');
ylabel('ECG (V)');
xlabel('Time(s)');

ax2=subplot(5,1,[3 4]);
h2_line2 = plot(data.Time,hr);
ylabel('HR (bpm)')
xlabel('Time (s)');

ax3=subplot(5,1,5);
h2_line3 = plot(data.Time,data.TTL,'linewidth',0.5);
hold on
h2_line4 =plot(data.Time,data.AirPuff,'linewidth',2);
ylabel('TTL (V)');
xlabel('Time (s)');

linkaxes([ax1 ax2 ax3],'x')
set_dark_mode(f1)
