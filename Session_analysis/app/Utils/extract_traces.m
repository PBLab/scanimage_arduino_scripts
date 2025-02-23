function extract_traces(app)
%EXTRACT_TRACES Summary of this function goes here
%   Detailed explanation goes here


%% Find rectangles in current projection
obj = findobj(app.ImgProjection.Children,'RotationAngle',0);
n_obj = numel(obj);
n_frames = size(app.FRAME_LUT,1);
sig_ch = app.PIPELINE.PARAMS.functional_ch;
num_channels = app.PIPELINE.PARAMS.num_channels;
ROIS = struct('ID',[],'Label',[],'Color',[],'Position',[],'Values',[]);
%% extract and plot average value from pixels in each ROI
set(app.Traces,'NextPlot','Replace');
for roi_i = 1:n_obj %stacked LIFO
    ROIS(roi_i).ID = roi_i;
    ROIS(roi_i).Label = obj(roi_i).Label;
    ROIS(roi_i).Position = round(obj(roi_i).Position);%[x y w h]
    x1 = ROIS(roi_i).Position(1);
    x2 = x1 + ROIS(roi_i).Position(3);
    y1 = ROIS(roi_i).Position(2);
    y2 = y1 + ROIS(roi_i).Position(4);
    vals = app.STK(x1:x2,y1:y2,sig_ch:num_channels:end);
    vals = reshape (vals,prod(size(vals,[1 2])),n_frames);
    ROIS(roi_i).Values = mean(vals);
    ROIS(roi_i).Color = obj(roi_i).Color;
     plot(app.Traces,app.FRAME_LUT.t_sec,ROIS(roi_i).Values,'Color',ROIS(roi_i).Color)
     set(app.Traces,'NextPlot','Add');
end


xlabel(app.Traces,'Time (s)');
ylabel(app.Traces,'ROI avg');




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

[PSTH] = compute_psth(app,ROIS)