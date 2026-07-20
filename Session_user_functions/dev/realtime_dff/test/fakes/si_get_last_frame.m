function frame = si_get_last_frame(hSI, channelIdx) %#ok<INUSD>
    % TEST FAKE — shadows dev/realtime_dff/si_get_last_frame.m on the path.
    % Serves frames one at a time from testFrameStack (set in base workspace by
    % the synthetic validation script), simulating successive frameAcquired pulls.
    persistent frames idx
    if isempty(frames)
        frames = evalin('base', 'testFrameStack');
        idx = 0;
    end
    idx = idx + 1;
    frame = frames(:, :, idx);
end
