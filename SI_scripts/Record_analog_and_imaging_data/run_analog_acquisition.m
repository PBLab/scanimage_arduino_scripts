%Record analog and imaging data
%This script takes care of simultaneously recording analog and imaging
%data. ScanImage has to be started from the script (otherwise there is a
%conflic wiht events which results in analog data being sent to the imaging
%stream. 
%
%The approach here is to have this scrip initiating the recording process,
%after setting parameters in the base workspace where all pertinent
%commnads will be executed. An user function "stop_analog_recording" closes
%the loop once the acquistion (imaging) is done.
% 
% Pablo - Jul 23th 2022.
close all
sample_rate = 1000; %samples per second - for plotting
clc
fprintf('Starting analog and imaging recording...');
%%prepare analog recording
analog_channels = [0 7];
set_analog_recording(hSI,analog_channels)

global ecg_R_vol_thresh
global mean_peak_dist 
global analog_buffer
global hr_history
global h2_line1
global h2_line2
global HR_BPM_conv_factor_sec


%Set up HR parameters
ecg_R_vol_thresh = 2; % threshold voltage to detect peaks 
mean_peak_dist = 90; % No need to change, unless acquisition parameters are modified 
HR_sample_window_sec = 1; % Size of window used to compute HR.
analog_samples_per_sec = 1000;
HR_sample_window_samples = HR_sample_window_sec*analog_samples_per_sec;
HR_BPM_conv_factor_sec = 60/HR_sample_window_sec;


analog_buffer = zeros (HR_sample_window_samples,1);
hr_history = NaN(analog_samples_per_sec/HR_sample_window_sec,1);
%% prepare graph output
figure('windowstyle','docked','Name','Analog data stream')
h2_axes1=subplot(2,1,1);
h2_line1 = plot(analog_buffer);
ylabel('ECG (V)');
xlabel('Samples');
h2_axes2=subplot(2,1,2);
h2_line2 = plot(hr_history);
ylabel('HR (bpm)')
xlabel('Time (s)');
%% start acquisition
hSI.startGrab
%start_analog_recording;
fprintf('Ending analog and imaging recording...');


%% display data sampled at 1000samples / sec
% analyze_ecg