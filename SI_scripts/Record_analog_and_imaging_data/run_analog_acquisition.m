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
% Last mod - Sept 1st 2023

close all
sample_rate = 1000; %samples per second - for plotting
clc
fprintf('Starting analog and imaging recording...');
%%prepare analog recording
analog_channels = struct('DeviceName',[],'Channel',[]);
analog_channels(1).DeviceName='Dev1';
analog_channels(1).Channel=[3];%scalar or vector
analog_channels(2).DeviceName='Dev2';
analog_channels(2).Channel=0; %ttk - frames
analog_channels(3).DeviceName='Dev2';
analog_channels(3).Channel=3;  %ttl - air puff 
set_analog_recording(hSI,analog_channels)

global ecg_R_vol_thresh
global mean_peak_dist 
global analog_buffer_ecg
global analog_buffer_ttl
global analog_buffer_ttl_airpuff
global hr_history
global h2_line1 %ecg
global h2_line2 %bpm
global h2_line3 %ttl
global h2_line4 %ttl airpuff
global HR_BPM_conv_factor_sec
global user_func_off
global analog_samples_per_sec

%Set up HR parameters
ecg_R_vol_thresh = 0.0005; % threshold voltage to detect peaks 
mean_peak_dist = 80; % No need to change, unless acquisition parameters are modified 
HR_sample_window_sec = 1; % Size of window used to compute HR.
analog_samples_per_sec = 1000;
HR_sample_window_samples = HR_sample_window_sec*analog_samples_per_sec;
HR_BPM_conv_factor_sec = 60/HR_sample_window_sec;

%set up buffers to hold data
analog_buffer_ecg = zeros (HR_sample_window_samples,1);%keep dedicated buffer for each channels
analog_buffer_ttl = zeros (HR_sample_window_samples,1);
analog_buffer_ttl_airpuff = zeros (HR_sample_window_samples,1);
hr_history = NaN(analog_samples_per_sec/HR_sample_window_sec,1);
%% prepare graph output
h2fig = figure('windowstyle','docked','Name','Analog data stream')
h2_axes1=subplot(5,1,[1 2]);
h2_line1 = plot(analog_buffer_ecg);
ylabel('ECG (V)');
xlabel('Samples');

h2_axes2=subplot(5,1,[3 4]);
h2_line2 = plot(hr_history);
ylabel('HR (bpm)')
xlabel('Time (s)');
hr_history=[];

h3_axes=subplot(5,1,5);
h2_line3 = plot(analog_buffer_ttl);
hold on
h2_line4 = plot(analog_buffer_ttl_airpuff);
ylabel('TTL (V)');
xlabel('Samples');
set_dark_mode(h2fig)

%% ensure user functions are enabled.
func_names = {'stop_analog_recording','stop_analog_recording','start_analog_recording'};
event_names = {'acqModeDone','acqAbort','acqModeArmed'};
arguments ={{},{},{}};
enable_on = {1,1,1};
enable_off = {0,0,0};
user_func_on = struct('EventName',event_names,'UserFcnName',func_names,'Arguments',arguments,'Enable',enable_on);
user_func_off= struct('EventName',event_names,'UserFcnName',func_names,'Arguments',arguments,'Enable',enable_off);
hSI.hUserFunctions.userFunctionsCfg = user_func_on;

%% start acquisition
hSI.startGrab

%% display data sampled at 1000samples / sec
% analyze_ecg