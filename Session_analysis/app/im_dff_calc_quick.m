function im_dff_calc_quick(app)
%Non-smoothed dff taking each 

%% compute for functional channel
sig_ch = app.PIPELINE.PARAMS.functional_ch;
num_channels = app.PIPELINE.PARAMS.num_channels;
[nr,nc,nframes] = size(app.STK);
app.STK_DF  = zeros(nr,nc,nframes/num_channels,'single');
F0 = single(mean(app.STK(:,:,sig_ch:num_channels:end),3));

%% loopish to avoid converting fron int16 to signle
nframes = size(app.STK,3);
for fi = sig_ch : num_channels : nframes
    app.STK_DF(:,:,fi) = (single(app.STK(:,:,fi)) - F0)./F0;
end
% app.STK_DF(isnan(app.STK_DF))=0;

app.STK_DF_MINMAX = [min(app.STK_DF(:)) max(app.STK_DF(:))];
