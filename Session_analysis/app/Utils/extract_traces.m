function extract_traces(app)
%EXTRACT_TRACES Summary of this function goes here
%   Detailed explanation goes here


%% Find rectangles in current projection
% obj = findobj(app.ImgProjection.Children,'RotationAngle',0);
obj = findobj(app.ImgProjection.Children,'Tag','ROI');
n_obj = numel(obj);
n_frames = size(app.FRAME_LUT,1);
sig_ch = app.PIPELINE.PARAMS.functional_ch;
num_channels = app.PIPELINE.PARAMS.num_channels;
ROIS = struct('ID',[],'Label',[],'Color',[],'Position',[],'Values',[],'dff',[]);
tau_0 = app.tau_0EditField.Value;
tau_1 = app.tau_0EditField.Value;
tau_2 = app.tau_0EditField.Value;
invert_vals = app.InvertCheckBox.Value;
fps = str2num(app.fpsEditField.Value);
%% extract and plot average value from pixels in each ROI
set(app.Traces,'NextPlot','Replace');
[m,n] = size(app.PROJ_MAX);
for roi_i = 1:n_obj %stacked LIFO
    ROIS(roi_i).ID = roi_i;
    ROIS(roi_i).Label = obj(roi_i).Label;
    % The commented lines worked for rectangles and now we move to polygons
    % ROIS(roi_i).Position = round(obj(roi_i).Position);%[x y w h]
    % x1 = ROIS(roi_i).Position(1);
    % x2 = x1 + ROIS(roi_i).Position(3);
    % y1 = ROIS(roi_i).Position(2);
    % y2 = y1 + ROIS(roi_i).Position(4);
    % vals = app.STK(x1:x2,y1:y2,sig_ch:num_channels:end);
    % vals = reshape (vals,prod(size(vals,[1 2])),n_frames);
    %ROIS(roi_i).Values = double(mean(vals));
    
    %% find region mask
    V = obj(roi_i).Position;
    M = poly2mask(V(:,1),V(:,2),m,n);
    idx = find(M);
    idx_offset = m*n;
    
    f_sig = sig_ch:num_channels:size(app.STK,3); %index the frames for the signal channel %safeguard 
    vals = zeros(n_frames,1); 
    for fi = 1:numel(f_sig)
        vals(fi) =mean(app.STK(idx + idx_offset *(f_sig(fi)-1)));
    end
    
    %%
    ROIS(roi_i).Values = vals;
    ROIS(roi_i).dff = dff_calc(ROIS(roi_i).Values,fps,tau_0,tau_1,tau_2,invert_vals);
    ROIS(roi_i).Color = obj(roi_i).Color;
    yyaxis(app.Traces,'left');
     plot(app.Traces,app.FRAME_LUT.t_sec,ROIS(roi_i).Values,'Color',ROIS(roi_i).Color)
     set(app.Traces,'NextPlot','Add');
     yyaxis(app.Traces,'right');
     plot(app.Traces,app.FRAME_LUT.t_sec,ROIS(roi_i).dff,'Color',ROIS(roi_i).Color,'LineStyle','--')

end

%%
yyaxis(app.Traces,'left');
xlabel(app.Traces,'Time (s)');
ylabel(app.Traces,'ROI avg');

yyaxis(app.Traces,'right');
ylabel(app.Traces,'dF/F');


%% Display stim
if (app.ShowStimCheckBox.Value)
    stims_ids = unique(app.STIM_TABLE.stim_id);
    n_stims = numel(stims_ids);
    stim_colors = copper(n_stims);
    y_max = max(app.Traces.YLim)*1.05;

    for si = 1 : n_stims
        valid_rows = app.STIM_TABLE.stim_id == stims_ids(si);
        X = [app.STIM_TABLE.start(valid_rows)' ;app.STIM_TABLE.start(valid_rows)';...
            app.STIM_TABLE.end(valid_rows)';app.STIM_TABLE.end(valid_rows)'];
        Y = repmat([0;y_max;y_max;0],1,size(X,2));
        patch(app.Traces,X,Y,'r','FaceColor',stim_colors(si,:),'FaceAlpha',0.5,'EdgeAlpha',0.5);
    end
end

set(app.Traces,'NextPlot','Replace','Box','off','XLimitMethod','tight','YLimitMethod','tight');

%% compute psth for the traces

[PSTH] = compute_psth(app,ROIS);