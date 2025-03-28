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
h2fig = figure('Name','Continous Peri stimulus/event ');
spi=reshape(1:n_rois*n_stims,n_rois,n_stims);
sp_counter = 1;
stim_colors = copper(n_stims);
for si = 1 : n_stims
    valid_rows = app.STIM_TABLE.stim_id == stims_ids(si);
    stim_frame_stars = app.STIM_TABLE.frame_start(valid_rows);
    stim_loc_i = frame_i+stim_frame_stars;
    %find out color and stim name
    stim_name_component = sprintf('Stim%dEditField',si);
    stim_name = app.(stim_name_component).Value;
    

    %% need safeguard against cases where stim_loc_i might point beyond
    %number of val elements
    n_vals = numel(ROIS(1).Values);
    %discard any stim that might start or end outside data
    max_r= max(stim_loc_i,[],2);
    stim_loc_i = stim_loc_i(max_r<=n_vals,:);
    min_r = min(stim_loc_i,[],2);
    stim_loc_i = stim_loc_i(min_r>0,:);
    %%
    for roi_i = 1 : numel(ROIS)
        %get all the events into a matrix (event x time)

        Y = ROIS(roi_i).Values(stim_loc_i);
        DFF = ROIS(roi_i).dff(stim_loc_i);
        %plot
        % subplot(n_rois,n_stims,(spi(sp_counter)))
                subplot(n_stims,n_rois,(spi(sp_counter)))

        yyaxis left;
        plot(t,Y','Color',[0.5 0.5 0.5],'LineStyle','-','marker','none')
        hold on
        plot(t,mean(Y),'lineW',3,'LineStyle','-','marker','none')
        title(sprintf('%s stim, ROI(%d)',stim_name,roi_i))
        box off 
        axis square
        ylabel('Intensity (a.u.)')
        xlabel('Time (s)')

        yyaxis right
        plot(t,DFF','Color',[0.5 0.5 0.5],'LineStyle','-','marker','none')
        hold on
        plot(t,mean(DFF),'lineW',3,'LineStyle','-','marker','none')
        box off 
        ylabel('\DeltaF /F0')
        sp_counter=sp_counter+1;
    end
end

%%
% h2a = findobj(h2fig,'Type','Axes');
% max_y = max(max(cell2mat(get(h2a,'ylim'))));
% min_y = min(min(cell2mat(get(h2a,'ylim'))));
% set(h2a,'Ylim',[min_y, max_y])

%%
%% 

