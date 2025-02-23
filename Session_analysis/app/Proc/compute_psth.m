function PSTH = compute_psth(app,ROIS)
%COMPUTE_PSTH Summary of this function goes here
%   Detailed explanation goes here


%%
PSTH=[];

%% compute frames indices offset before/after frame start
stim_frame_stars = app.STIM_TABLE.frame_start;
stims_ids = unique(app.STIM_TABLE.stim_id);
n_stims = numel(stims_ids);
stim_colors = copper(n_stims);

fps = mean(diff(app.FRAME_LUT{:,2}));
t_before_s = app.PSTHbeforesEditField.Value;
t_after_s = app.PSTHaftersEditField.Value;
t=-t_before_s:fps:t_after_s;
frames_before = round(t_before_s/fps);
frames_after = round(t_after_s/fps);
frame_i = -frames_before:frames_after;
n_rois = numel(ROIS);
figure('Name','Continous Peri stimulus/event ')
clc
spi=reshape([1:n_rois*n_stims], n_stims,n_rois)';
sp_counter = 1;
for si = 1 : n_stims
    valid_rows = app.STIM_TABLE.stim_id == stims_ids(si);
    stim_frame_stars = app.STIM_TABLE.frame_start(valid_rows);
    stim_loc_i = frame_i+stim_frame_stars;
    for roi_i = 1 : numel(ROIS)
        %get all the events into a matrix (event x time)

        Y = ROIS(roi_i).Values(stim_loc_i);
        %plot
        subplot(n_rois,n_stims,(spi(sp_counter)))
        plot(t,Y','Color',[0.5 0.5 0.5])
        hold on
        plot(t,mean(Y),'Color','k','lineW',2)
        title(sprintf('Stim(%d), ROI(%d)',si,roi_i))
        box off 
        sp_counter=sp_counter+1;
    end
end

