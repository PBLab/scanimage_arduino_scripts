
TTL_threshold_V = 3;
TTL_distance = 5;
ECG_threshold_V = 0.2;
ECG_distance = 50; 
analog_file_name = dir('*analog.csv');

%% read  analog data
file_i = 1;
analog_data = readtable(analog_file_name(file_i).name);
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
    bar(v,counts)
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
    T=[T;ev];

end
%% find start and end frames
T=T(:,[4:7 1:3]);
fprintf('\n')
disp(T)


%%
base_file_name = analog_file_name.name(1:strfind(analog_file_name.name,'analog.csv'));
writetable(T,[base_file_name,'_stims.csv'])

lut.frame_id = frame_id;
lut.t_sec =t_loc_time;

writetable(struct2table(lut),[base_file_name,'_lut.csv'])

