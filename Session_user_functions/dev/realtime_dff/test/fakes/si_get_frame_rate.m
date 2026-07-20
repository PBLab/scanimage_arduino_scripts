function fps = si_get_frame_rate(hSI) %#ok<INUSD>
    % TEST FAKE — shadows dev/realtime_dff/si_get_frame_rate.m on the path.
    % Returns the fixed fps set in base workspace by the synthetic validation script.
    fps = evalin('base', 'testFps');
end
