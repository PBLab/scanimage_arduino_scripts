function plotData(event)
global ecg_R_vol_thresh
global mean_peak_dist 
global analog_buffer
global hr_history
global h2_line1 % handle to lines
global h2_line2
global HR_BPM_conv_factor_sec

%      time = event.TimeStamps;
     data = event.Data;
%      size(data)
%      [locs_Rwave] = find_R_peaks(data(:,1),ecg_R_vol_thresh,mean_peak_dist);
% 
%      plot(time,data)
%      hold on
%      plot(time(locs_Rwave),data(locs_Rwave,1),'r^')

 % add to buffer
 samples_per_chunk = size(data,1);
    analog_buffer = [analog_buffer(samples_per_chunk+1:end) ;data(:,1)];
%     plot(h2_axes1,analog_buffer);drawnow

set(h2_line1,'ydata',analog_buffer);

    %compute hr
    [locs_Rwave] = find_R_peaks(analog_buffer,ecg_R_vol_thresh,mean_peak_dist);
    hr = numel(locs_Rwave)*HR_BPM_conv_factor_sec;
    hr_history = [hr_history;hr];
%     plot(h2_axes2,hr_history);
    set(h2_line2,'ydata',hr_history);

%     data_chunk_idx = data_chunk_idx + samples_per_chunk;
% 
end