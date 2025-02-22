function [stk,analog_table] = load_single_session(app)
%LOAD_SINGLE_SESSION loads content of single session (from the 'ophys'
%directory)
%   Function will load the content of a session from the ophys file
%   expected content is
% .tiff file with imaging data
% .xml file with metadata
% *.analog.csv with analog recorded data (optional) TIME, ECG, TTL [,STIM]
%  Pablo

stk = [];
analog_table = [];
%%
logger(app,sprintf('%s',repmat('-',100,1)))
app.PATH_TO_SESSION;
if exist(app.PATH_TO_SESSION,'dir')
    path_to_session = app.PATH_TO_SESSION;
else
    path_to_session = cd;
end

app.PATH_TO_SESSION = uigetdir(path_to_session,'Select session root file (the one containing the ophys directory');

logger(app,sprintf('Beginning data loading for session %s',app.PATH_TO_SESSION))
%% load analog data
path_to_ophys = fullfile(app.PATH_TO_SESSION,'ophys');
dir_content = dir(fullfile(path_to_ophys,'*_analog.csv'));
if ~isempty(dir_content)

    path_to_analog_file_name = fullfile(path_to_ophys,dir_content.name);
    [app.STIM_TABLE, app.FRAME_LUT,analog_table] = parse_analog_data(path_to_analog_file_name,app.PIPELINE.PARAMS);

    %% write tables to derivates directory
    path_to_derivates = fullfile(app.PATH_TO_SESSION,'derivates');
    lut_filename = fullfile(path_to_derivates,'frame_lut.csv');
    writetable(app.FRAME_LUT, lut_filename);
    stim_filename = fullfile(path_to_derivates,'stim_epochs.csv');
    writetable(app.STIM_TABLE,stim_filename)
    logger(app,'Parsed analog data saved to session derivates directory')

    logger(app,'Updating analog plots')
    %% plot analog data
    plot(app.plot_TTL,analog_table.Time,analog_table.TTL);
    plot(app.plot_ECG,analog_table.Time,analog_table.ECG);
    plot(app.plot_STIM,analog_table.Time,analog_table.STIM);
    set(app.plot_STIM,'NextPlot','add')
    %construct STIM (burst-grouped) signal
    s = zeros(size(analog_table.Time,1),1);
    for si = 1 : size(app.STIM_TABLE,1)
        s(app.STIM_TABLE{si,"start_sample"}:app.STIM_TABLE{si,"end_sample"}) = app.STIM_TABLE{si,'voltage'};
    end
    plot(app.plot_STIM,analog_table.Time,s,'LineWidth',2)
    set(app.plot_STIM,'NextPlot','replace')
    xlim(app.plot_TTL,[analog_table.Time(1) analog_table.Time(end)])
    set(app.plot_TTL,'XLimitMethod','tight')
    %link analog x-axis
    linkaxes([app.plot_TTL app.plot_ECG, app.plot_STIM],'x')
else
    logger(app,'WARNING - No analog data in ophys directory')
end
%% load imaging data
logger(app,'Loading tif file')
dir_content = dir(fullfile(path_to_ophys,'*.tif'));

if ~isempty(dir_content)
    path_to_tif = fullfile(path_to_ophys,dir_content.name);
    % stk = scanimage.util.ScanImageTiffReader(path_to_tif);%need to compile mex file
    app.STK = loadmovie(path_to_tif);
else
    logger(app,'WARNING - No imaging (.tif) data in ophys directory')
end

%% display  data channel and update slider
n_channels = app.PIPELINE.PARAMS.num_channels; %HARDCODED!!!!
sig_ch = app.PIPELINE.PARAMS.functional_ch;
n_frames = size(app.FRAME_LUT,1);

%update slider range
app.Slider_time.Limits=[1,n_frames];
app.Slider_time.Value = 1;
imagesc(app.Image,app.STK(:,:,1))
axis(app.Image,'image')
colormap(app.Image,'Gray')
colorbar(app.Image,'eastoutside')

logger(app,'Computing and saving projections to derivates')
app.PROJ_MAX = squeeze(max(app.STK(:,:,sig_ch:n_channels:end),[],3));
app.PROJ_AVG = squeeze(mean(app.STK(:,:,sig_ch:n_channels:end),3));
app.PROJ_STD = squeeze(std(single(app.STK(:,:,sig_ch:n_channels:end)),0,3));
app.PROJ_MED = squeeze(median(app.STK(:,:,sig_ch:n_channels:end),3));

imagesc(app.ImgProjection,app.PROJ_MAX)
axis(app.ImgProjection,'image')
colormap(app.ImImgProjectionage,'Gray')
linkaxes([app.Image app.ImgProjection],'xy')
%%
logger(app,'Done')
end

