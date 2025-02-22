function [T,lut,A] = parse_analog_data(path_to_analog_file_name,params)
%PARSE_ANALOG_DATA loads analog data recorded alongside imaging data to
%create a LUT between data streams, also parses STIM data if present 



%get parameters
TTL_threshold_V = params.TTL_threshold_V;
TTL_distance = params.TTL_distance;
ECG_threshold_V = params.ECG_threshold_V;
ECG_distance = params.ECG_distance; 

%% read  analog data
analog_data = readtable(path_to_analog_file_name);
flag_stim_ch = 0;
switch size(analog_data,2)
    case 3
        analog_data.Properties.VariableNames={'Time','ECG','TTL'};
    case 4
        analog_data.Properties.VariableNames={'Time','ECG','TTL','STIM'};
        flag_stim_ch = 1;
end


%% crop analog by finding first time point above TTL threshold
x_start = find (analog_data.TTL>=TTL_threshold_V,1,'first');
x_end = find (analog_data.TTL>=TTL_threshold_V,1,'last');

A = analog_data(x_start:x_end,:);
A.Time = A.Time - A.Time(1);

%% determine the frame to analog LUT, finding the min value location is a good indicator of frame timming

TTL = A.TTL;
TTL(TTL<TTL_threshold_V) = 0;
[~,f_loc] = findpeaks(diff(TTL,1),'Threshold',TTL_threshold_V/2,'MinPeakDistance',TTL_distance);
f_loc = [1;f_loc];
n_frames = numel(f_loc);
t_loc_time = A.Time(f_loc);
frame_id = (1:numel(t_loc_time))';
A.frame_id = round(interp1(t_loc_time,frame_id,A.Time));

fprintf('\nIdentified %d frames taken in %3.2f sec resulting in %3.2f fps',...
    n_frames,t_loc_time(end),n_frames/t_loc_time(end))

%% Parse STIM intervals if present

%find out STIM levels
if flag_stim_ch > 0
    %attemp to detect "levels" of stim
    [counts,v_edges] = histcounts(A.STIM(A.STIM>0.1),0:0.5:5); %the 0.1 is just to get rid of baseline
    v = mean([v_edges(1:end-1);v_edges(2:end)]);
end

%% keep only events with more than 100 samples timepoints (in analog data)
valid_stims = counts>100;
stim_v = v(valid_stims)-0.25;
fprintf('\nThere are %d stim levels:',numel(stim_v));
fprintf('\n%.2f V',stim_v)
n_stims  = sum(valid_stims);
T=[];
for stim_i = 1:n_stims
    stim_loc_i = A.STIM > stim_v(stim_i) & A.STIM<stim_v(stim_i)+.25;
    stim_loc_t = A.Time(stim_loc_i);
    signal = zeros(length(A.STIM),1);
    signal(stim_loc_i)=1;
    %group square signals into bouts
    ev = groupSquareWaveBursts(A.Time,signal);

    ev = struct2table(ev);
    ev.stim_id = zeros(size(ev,1),1)+stim_i;
    ev.voltage = zeros(size(ev,1),1)+stim_v(stim_i);
    ev.frame_start = round(interp1(t_loc_time,frame_id,ev.start));
    ev.frame_end = round(interp1(t_loc_time,frame_id,ev.end));
    ev.start_sample = f_loc(ev.frame_start);
    ev.end_sample = f_loc(ev.frame_end);
    T=[T;ev];

end
%% find start and end frames
T=T(:,[4:7 1:3 8:9]);
fprintf('\n')
lut.frame_id = frame_id;
lut.t_sec =t_loc_time;

lut = struct2table(lut);