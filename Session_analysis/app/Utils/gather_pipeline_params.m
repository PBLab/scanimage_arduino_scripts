function PIPELINE = gather_pipeline_params(app)
%GATHER_PIPELINE_PARAMS gather current paramets/task from GUI

%% populate parameters
app.PIPELINE =[];
proc.split_channels = app.SplitchannelsCheckBox.Value;
proc.motion_correct = app.MotioncorrectCheckBox.Value;
proc.compute_df = app.ComputedffCheckBox.Value;
proc.compute_psth = app.ComputePSTHCheckBox.Value;

params.mc_ch = str2double(app.MotionCorrectionChDropDown.Value);
params.df_ch = str2double(app.SignalChDropDown.Value);
params.TTL_threshold_V = app.TTLthresholdEditField.Value;
params.TTL_distance = app.TTLdistanceEditField.Value;
params.ECG_threshold_V = app.ECGthresholdEditField.Value;
params.ECG_distance = app.ECGdistanceEditField.Value;
params.num_channels = str2double(app.NumberofchannelsDropDown.Value);
params.motion_corr_ch = str2double(app.MotionCorrectionChDropDown.Value);
params.functional_ch = str2double(app.SignalChDropDown.Value);

app.PIPELINE.PROC = proc;
app.PIPELINE.PARAMS = params;
end


