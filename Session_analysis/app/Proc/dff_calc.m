function dff = dff_calc(data, fps, tau_0, tau_1, tau_2, invert)
    % Calculates dF/F from calcium traces, based on
    % https://www.nature.com/articles/nprot.2010.169.
    %
    % Parameters
    % ----------
    % data : matrix
    %     dF/F traces with dimensions (cell x time)
    % fps : float, optional
    %     Frame rate (Hz)
    % tau_0 : float, optional
    %     Exponential smoothing factor in seconds
    % tau_1 : float, optional
    %     F0 smoothing parameter in seconds
    % tau_2 : float, optional
    %     Time window before each measurement to minimize
    % invert : bool, optional
    %     False (default) if the transient is expected to be positive, True
    %     otherwise.
    %
    % Returns
    % -------
    % dff : matrix
    %     A 2D array, each row being a calculated dF/F trace.

    if nargin < 2, fps = 30.0; end
    if nargin < 3, tau_0 = 0.1; end
    if nargin < 4, tau_1 = 0.35; end
    if nargin < 5, tau_2 = 2.0; end
    if nargin < 6, invert = false; end

    [tau_0, tau_1, tau_2, min_per] = apply_units_and_corrections(fps, tau_0, tau_1, tau_2);
    if invert
        data = -data;
    end

    f0 = calc_f0(data, tau_1, tau_2, min_per);
    unfiltered_dff = calc_dff_unfiltered(f0, data);
    dff = filter_dff(unfiltered_dff, tau_0, min_per);
end

function [tau_0, tau_1, tau_2, min_per] = apply_units_and_corrections(fps, tau_0, tau_1, tau_2)
    % Correct the given parameters based on the FPS
    tau_0 = fps * tau_0;
    tau_1 = round(fps * tau_1);
    tau_2 = round(fps * tau_2);
    min_per = max(1, round(fps / 10));
end

function f0 = calc_f0(data, tau_1, tau_2, min_per)
    % Create the F_0(t) baseline for the dF/F calculation using a boxcar window.
    data = data';
    f0 = movmean(data, [tau_1-1, 0], 1, 'Endpoints', 'shrink');
    f0 = movmin(f0, [tau_2-1, 0], 1, 'Endpoints', 'shrink');
    
    % Handle cases where the number of observations is less than min_per
    f0 = arrayfun(@(col) enforce_min_per(f0(:, col), tau_2, min_per), 1:size(f0, 2), 'UniformOutput', false);
    f0 = cell2mat(f0);
    
    f0 = f0 + eps;
end

function unfiltered_dff = calc_dff_unfiltered(f0, data)
    % Subtract baseline from current fluorescence
    data = data';
    raw_calc = (data - f0) ./ f0;
    raw_calc(isnan(raw_calc)) = 0;
    unfiltered_dff = raw_calc;
end

function dff = filter_dff(unfiltered_dff, tau_0, min_per)
    % Apply an exponentially weighted moving average to the dF/F data.
    alpha = 1 - exp(-log(2) / tau_0);
    dff = filter(alpha, [1, alpha-1], unfiltered_dff, [], 1);
    
    % Handle cases where the number of observations is less than min_per
    dff = arrayfun(@(col) enforce_min_per(dff(:, col), tau_0, min_per), 1:size(dff, 2), 'UniformOutput', false);
    dff = cell2mat(dff);
    
    dff(isnan(dff)) = 0;
    dff = dff';
end

function column = enforce_min_per(column, window_size, min_per)
    % Set elements to NaN if the number of observations in the window is less than min_per
    for i = 1:length(column)
        start_idx = max(1, i - window_size + 1);
        if (i - start_idx + 1) < min_per
            column(i) = NaN;
        end
    end
end
