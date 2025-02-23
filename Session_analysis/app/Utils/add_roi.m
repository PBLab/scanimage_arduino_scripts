function add_roi(app)
%ADD_ROI interactively add roi to image
%   Detailed explanation goes here

%figure out how many ROIs are already in the plot


roi_colors = lines(256);
%% find existing rectangles
obj = findobj(app.ImgProjection.Children,'RotationAngle',0);
n_obj = numel(obj);
if n_obj>256;roi_colors = lines(n_obj+1);end
%%
h2rect = drawrectangle(app.ImgProjection);
h2rect.Label = sprintf('ROI_%d',n_obj+1);
h2rect.Color = roi_colors(n_obj+1,:);

%% extract data
% sig_ch = app.PIPELINE.PARAMS.functional_ch;
% n_ch = app.PIPELINE.PARAMS.num_channels;
% f = app.STK(,:)

