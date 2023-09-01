function plotData(event)
global ecg_R_vol_thresh
global mean_peak_dist
global analog_buffer_ecg
global analog_buffer_ttl
global analog_buffer_ttl_airpuff
global hr_history
global h2_line1 %ecg
global h2_line2 %bpb
global h2_line3 %ttl
global h2_line4 %airpuff
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
analog_buffer_ecg = [analog_buffer_ecg(samples_per_chunk+1:end) ;data(:,1)];
analog_buffer_ttl = [analog_buffer_ttl(samples_per_chunk+1:end) ;data(:,2)];
analog_buffer_ttl_airpuff = [analog_buffer_ttl_airpuff(samples_per_chunk+1:end) ;data(:,3)];
%     plot(h2_axes1,analog_buffer);drawnow

set(h2_line1,'ydata',analog_buffer_ecg);
set(h2_line3,'ydata',analog_buffer_ttl);
set(h2_line4,'ydata',analog_buffer_ttl_airpuff);
%compute hr
[locs_Rwave] = find_R_peaks(analog_buffer_ecg,ecg_R_vol_thresh,mean_peak_dist);
hr = numel(locs_Rwave)*HR_BPM_conv_factor_sec;
hr_history = [hr_history;hr];
%     plot(h2_axes2,hr_history);
set(h2_line2,'ydata',hr_history);

%     data_chunk_idx = data_chunk_idx + samples_per_chunk;
%
end