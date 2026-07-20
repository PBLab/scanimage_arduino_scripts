function si_register_user_functions(hSI, eventFcnMap) %#ok<INUSD>
    % TEST FAKE — shadows dev/realtime_dff/si_register_user_functions.m on the
    % path. No live ScanImage session exists in the synthetic harness, so this
    % is a no-op; the test script drives dff_on_acq_mode_start/frame_acquired directly.
end
