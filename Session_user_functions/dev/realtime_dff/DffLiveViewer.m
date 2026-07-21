classdef DffLiveViewer < handle
    % Standalone live-plot window for the real-time df/f monitor. Decoupled from
    % the offline Session_analysis app — owns its own figure/axes/state.

    properties
        Figure
        Axes_img
        h2_dff_img
        Axes_trace
        LineHandle
    end

    methods
        function obj = DffLiveViewer()
            obj.createFigure();
        end

        function reset(obj)
            % FR2: clear/open the dedicated window for a new acquisition.
            if isempty(obj.Figure) || ~isvalid(obj.Figure)
                obj.createFigure();
            else
                figure(obj.Figure);
                set(obj.LineHandle, 'XData', NaN, 'YData', NaN);
                obj.h2_dff_img = imagesc(NaN(256));
            end
        end

        function update(obj, frame,tSec, dffTrace)
            % FR4: refresh the live plot with the current ordered trace.
            set(obj.LineHandle, 'XData', gather(tSec), 'YData', gather(dffTrace));
            set(obj.h2_dff_img,'CData',gather(frame));
            drawnow limitrate;

        end
    end

    methods (Access = private)
        function createFigure(obj)
            obj.Figure = figure('Name', 'Real-time df/f', 'NumberTitle', 'off');
            %
            obj.Axes_img= subplot(1,2,1)
            obj.h2_dff_img = imagesc(obj.Axes_img,NaN(256));
            axis image
            axis off
            obj.Axes_trace = subplot(1,2,2);
            obj.LineHandle = plot(obj.Axes_trace,NaN,NaN);
            xlabel(obj.Axes_trace, 'Time (s)');
            ylabel(obj.Axes_trace, 'df/f');
            title(obj.Axes_trace, 'Real-time df/f');
            h2push = uicontrol;
            h2push.String = "Add Roi";
            % h2push.Callback = @(obj)dff_add_roi;
            h2push.Callback = @obj.add_roi;
        end

        function add_roi(varargin)
            DffViewerObj=varargin{1};
            h2axes = DffViewerObj.Axes_img;
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
        end % ADD ROI
    end
end
