function update_proj_display(app)
%update_proj_display Swaps projection display between already computed
%projections.

proj_type = app.ProjectionDropDown.Value;
switch proj_type
    case{'Max'}
        proj = app.PROJ_MAX;
    case{'Mean'}
        proj = app.PROJ_AVG;
    case{'Std'}
        proj = app.PROJ_STD;
    case{'Median'}
        proj = app.PROJ_MED;
end

imagesc(app.ImgProjection,proj)
axis(app.ImgProjection,'image')
colormap(app.ImgProjection,'turbo')
colorbar(app.ImgProjection,'eastoutside')
end

