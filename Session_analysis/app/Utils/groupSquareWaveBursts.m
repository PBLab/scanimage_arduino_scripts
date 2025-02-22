function events = groupSquareWaveBursts(time, signal)
    % Identify rising edges of square waves
    edges = find(diff(signal) > 0) + 1;
    
    % Ensure there are pulses to form events
    if isempty(edges)
        warning('No pulses detected');
        events = [];
        return;
    end
    
    % Identify gaps between pulses
    time_diffs = diff(time(edges));
    threshold = median(time_diffs) * 2; % Define a gap threshold based on median time difference
    burst_indices = [1; find(time_diffs > threshold) + 1; length(edges) + 1];
    
    % Group pulses into bursts
    events = struct('start', [], 'end', [], 'duration', []);
    for i = 1:length(burst_indices) - 1
        start_idx = burst_indices(i);
        end_idx = burst_indices(i + 1) - 1;
        events(i).start = time(edges(start_idx));
        events(i).end = time(edges(end_idx));
        events(i).duration = events(i).end - events(i).start;
    end
end