classdef DffLiveViewer < handle
    % Standalone live-plot window for the real-time df/f monitor. Decoupled from
    % the offline Session_analysis app — owns its own figure/axes/state.

    properties
        Figure
        Axes_img
        h2_dff_img
        Axes_trace
        LineHandles
        AddRoiButton
    end

    methods
        function obj = DffLiveViewer()
            obj.LineHandles = gobjects(0);
            obj.createFigure();
        end

        function reset(obj)
            % FR2: clear/open the dedicated window for a new acquisition.
            % Only updates the image CData (never recreates the image object or
            % clears the axes) so any ROI polygons drawn on Axes_img survive a
            % reset — ROIs are meant to persist across acquisitions.
            if isempty(obj.Figure) || ~isvalid(obj.Figure)
                obj.createFigure();
            else
                figure(obj.Figure);
                set(obj.h2_dff_img, 'CData', NaN(256));
            end
        end

        function setTraces(obj, labels, colors)
            % Rebuild the trace line handles for the upcoming run: one whole-FOV
            % line, or one per ROI (colored to match each ROI's drawn color).
            delete(obj.LineHandles(isgraphics(obj.LineHandles)));
            n = numel(labels);
            obj.LineHandles = gobjects(1, n);
            hold(obj.Axes_trace, 'on');
            for i = 1:n
                obj.LineHandles(i) = plot(obj.Axes_trace, NaN, NaN, 'Color', colors(i, :));
            end
            hold(obj.Axes_trace, 'off');
            if n > 1
                legend(obj.Axes_trace, labels, 'Location', 'best');
            else
                legend(obj.Axes_trace, 'off');
            end
        end

        function update(obj, frame, tSec, dffMatrix)
            % FR4: refresh the live plot with the current ordered trace(s), one
            % column of dffMatrix per line handle.
            tSec = gather(tSec);
            dffMatrix = gather(dffMatrix);
            for i = 1:numel(obj.LineHandles)
                set(obj.LineHandles(i), 'XData', tSec, 'YData', dffMatrix(:, i));
            end
            set(obj.h2_dff_img,'CData',gather(frame));
            drawnow limitrate;

        end

        function lockRois(obj)
            % Freeze ROI editing for the duration of an acquisition: disable the
            % Add-ROI button and make existing ROIs non-interactive/non-deletable.
            obj.AddRoiButton.Enable = 'off';
            rois = findobj(obj.Axes_img, 'Tag', 'ROI');
            for i = 1:numel(rois)
                rois(i).InteractionsAllowed = 'none';
                rois(i).Deletable = false;
            end
        end

        function unlockRois(obj)
            % Re-enable ROI editing once acquisition stops (acqDone).
            obj.AddRoiButton.Enable = 'on';
            rois = findobj(obj.Axes_img, 'Tag', 'ROI');
            for i = 1:numel(rois)
                rois(i).InteractionsAllowed = 'all';
                rois(i).Deletable = true;
            end
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
            xlabel(obj.Axes_trace, 'Time (s)');
            ylabel(obj.Axes_trace, 'df/f');
            title(obj.Axes_trace, 'Real-time df/f');
            obj.setTraces({'whole FOV'}, [0 0.4470 0.7410]);
            obj.AddRoiButton = uicontrol;
            obj.AddRoiButton.String = "Add Roi";
            obj.AddRoiButton.Callback = @obj.add_roi;
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

            % BUG: label is derived from the current COUNT of ROIs (n_obj+1), not
            % from labels actually in use. Delete a non-last ROI (e.g. ROI_2 out of
            % ROI_1/ROI_2/ROI_3) then add a new one: n_obj becomes 2, so the new ROI
            % is labeled ROI_3, colliding with the existing ROI_3. Needs a fix that
            % checks existing labels (or tracks a monotonically increasing counter)
            % rather than recomputing the label from numel().
            h2rect = drawpolygon(h2axes);
            h2rect.Label = sprintf('ROI_%d',n_obj+1);
            h2rect.Color = roi_colors(n_obj+1,:);
            h2rect.Tag='ROI';
        end % ADD ROI
    end
end
