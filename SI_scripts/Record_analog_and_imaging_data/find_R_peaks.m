function [locs_Rwave,locs_Swave] = find_R_peaks(ECG,ecg_R_vol_thresh,mean_peak_dist)
%find_R_peaks Looks for R peak component in EEG signal
%   Analysis of ECG signal
% Input -
%   ECG - n-by-1 vector with ECG data (voltage)
%   ecg_R_vol_thresh - threshold value for finding peaks
%   mean_peak_dist - parameter to control the Min distance (number of samples) between
%   peaks.
% Output -
%   locs_Rwave and locs_SWave are n-by-number_of_peaks found vectors with the location
%   (index) of the peaks.
%
%Pablo - Nov 2022

%R-component
[~,locs_Rwave] = findpeaks(ECG,'MinPeakHeight',ecg_R_vol_thresh,...
    'MinPeakDistance',mean_peak_dist);
if nargout>1
    %S-component is min ECG
    [~,locs_Swave] = findpeaks(-ECG,'MinPeakHeight',0.5,...
        'MinPeakDistance',mean_peak_dist);
end
end

