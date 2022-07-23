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


%%prepare analog recording
analog_channels = [0 1 3];
set_analog_recording(analog_channels)

%delete(dq);%just for DEV!!!

%% start acquisition
hSI.startGrab
start_analog_recording(analog_channels);