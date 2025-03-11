function update_proj_display(app)
%update_proj_display Swaps projection display between already computed
%projections.

%%
proj_type = app.ProjectionDropDown.Value;
im_type = app.ShowDataTypeDropDown.Value;
switch im_type
    case 'Raw'
        color_map = 'gray';
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
    case 'dFF'
        color_map ='turbo';
        switch proj_type
            case{'Max'}
                proj = app.PROJ_DF_MAX;
            case{'Mean'}
                proj = app.PROJ_DF_AVG;
            case{'Std'}
                proj = app.PROJ_DF_STD;
            case{'Median'}
                proj = app.PROJ_DF_MED;
        end
end

imagesc(app.ImgProjection,proj)
axis(app.ImgProjection,'image')
colormap(app.ImgProjection,color_map)
colorbar(app.ImgProjection,'eastoutside')
end

