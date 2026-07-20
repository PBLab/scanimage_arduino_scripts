function dff_add_roi(DffViewerObj)
%ADD_ROI interactively add roi to image in dff viewer (obj)

%figure out how many ROIs are already in the plot


%%
h2axes = get(DffViewerObj.Axes_img,"Parent");
roi_colors = lines(256);
%% find existing rectangles
obj = findobj(h2axes,'Tag','ROI');
n_obj = numel(obj);
if n_obj>256;roi_colors = lines(n_obj+1);end
%%
% h2rect = drawrectangle(app.ImgProjection);

h2rect = drawpolygon(h2axes);
h2rect.Label = sprintf('ROI_%d',n_obj+1);
h2rect.Color = roi_colors(n_obj+1,:);
h2rect.Tag='ROI';

%% extract data
% sig_ch = app.PIPELINE.PARAMS.functional_ch;
% n_ch = app.PIPELINE.PARAMS.num_channels;
% f = app.STK(,:)

