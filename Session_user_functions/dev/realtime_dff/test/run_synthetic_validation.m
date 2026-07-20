function run_synthetic_validation()
    % Stage 1 (Signal Injection) synthetic validation for the real-time df/f
    % pipeline, per CLAUDE.md §8. Exercises everything EXCEPT the three
    % unverified ScanImage adapters (si_get_last_frame, si_get_frame_rate,
    % si_register_user_functions), which are shadowed with test fakes in
    % test/fakes/ — those adapters are intentionally out of scope here; see
    % feedback_scanimage_api_verification memory.
    %
    % Validates: circular FIFO buffer write/eviction (FR3), trace
    % reconstruction ordering after wraparound (design doc §7), end-to-end
    % wiring through dff_calc.m to the live viewer (FR4), acqModeStart reset
    % discarding prior state (AC4), and recovery of a known injected df/f
    % transient at the expected location in time (AC3 spirit).
    %
    % Labeled synthetic per CLAUDE.md — never mixed with real analysis outputs.

    thisDir = fileparts(mfilename('fullpath'));
    mainDir = fileparts(thisDir);                                  % dev/realtime_dff
    fakesDir = fullfile(thisDir, 'fakes');
    procDir = fullfile(mainDir, '..', '..', '..', 'Session_analysis', 'app', 'Proc');

    addpath(mainDir);
    addpath(procDir);
    addpath(fakesDir);  % added last -> highest precedence, shadows si_*.m in mainDir

    dff_monitor_instance('clear');
    clear si_get_last_frame si_get_frame_rate  % reset fakes' persistent state

    % --- Synthetic data generation (seeded, reproducible) ---
    seed = 42;
    rng(seed);

    fps = 30;
    windowSeconds = 20;
    windowSamples = round(fps * windowSeconds);   % 600
    H = 16; W = 16;
    nFrames = 900;                                 % > windowSamples, forces wraparound
    baseline = 200;
    pixelNoiseStd = 1.0;

    injCenterFrame = 800;      % absolute frame index of the injected transient's peak
    injSigmaFrames = 15;       % ~0.5s width
    injAmplitude = 60;         % 30% of baseline

    t = (1:nFrames)';
    injectedTimecourse = injAmplitude * exp(-0.5 * ((t - injCenterFrame) / injSigmaFrames).^2);

    frameStackDouble = zeros(H, W, nFrames);
    for k = 1:nFrames
        frameStackDouble(:, :, k) = baseline + injectedTimecourse(k) + pixelNoiseStd * randn(H, W);
    end
    frameStack = int16(round(frameStackDouble));
    groundTruthMeans = squeeze(mean(mean(double(frameStack), 1), 2));  % nFrames x 1

    assignin('base', 'testFrameStack', frameStack);
    assignin('base', 'testFps', fps);

    logDir = fullfile(thisDir, 'synthetic_logs');  % clearly labeled synthetic output

    % --- Drive the pipeline exactly as ScanImage would, minus the adapters ---
    hSI = struct('note', 'synthetic placeholder — unused, adapters are faked');
    cfgOverrides = struct('channelIdx', 1, 'windowSeconds', windowSeconds, 'logDir', logDir);

    dff_realtime_init(hSI, cfgOverrides);
    mon = dff_monitor_instance('get');

    dff_on_acq_mode_start(struct(), struct());
    assert(mon.WindowSamples == windowSamples, 'WindowSamples mismatch: got %d, expected %d', ...
        mon.WindowSamples, windowSamples);
    assert(mon.NFilled == 0 && mon.WritePtr == 0, 'Buffer not reset after acqModeStart');

    for k = 1:nFrames
        dff_on_frame_acquired(struct(), struct());
    end

    % --- Check 1: buffer fully wrapped as expected ---
    assert(mon.NFilled == windowSamples, 'NFilled=%d, expected full buffer %d', mon.NFilled, windowSamples);
    expectedWritePtr = mod(nFrames, windowSamples);
    assert(mon.WritePtr == expectedWritePtr, 'WritePtr=%d, expected %d', mon.WritePtr, expectedWritePtr);

    % --- Check 2: FIFO write-position correctness (FR3) ---
    lastSlot = mod(nFrames - 1, windowSamples) + 1;
    bufferedLastFrame = gather(mon.FrameBuffer(:, :, lastSlot));
    assert(isequal(bufferedLastFrame, frameStack(:, :, nFrames)), ...
        'FrameBuffer slot %d does not match the last frame served (FIFO write-position bug)', lastSlot);

    % --- Check 3: trace reconstruction matches ground truth (design §7) ---
    expectedTrace = groundTruthMeans(nFrames - windowSamples + 1:nFrames);
    liveTrace = gather(mon.currentTrace());
    traceMaxAbsDiff = max(abs(liveTrace - expectedTrace));
    assert(traceMaxAbsDiff < 1e-6, 'Reconstructed trace diverges from ground truth: maxAbsDiff=%.3g', traceMaxAbsDiff);

    % --- Check 4: end-to-end wiring matches an independent offline dff_calc call (FR4) ---
    dffParams = dff_default_params().dffParams;
    offlineDff = gather(dff_calc(gpuArray(expectedTrace), fps, dffParams.tau_0, dffParams.tau_1, ...
        dffParams.tau_2, dffParams.invert));
    liveDff = gather(get(mon.Viewer.LineHandle, 'YData'))';
    dffMaxAbsDiff = max(abs(liveDff - offlineDff));
    assert(dffMaxAbsDiff < 1e-6, 'Live viewer dff diverges from offline dff_calc: maxAbsDiff=%.3g', dffMaxAbsDiff);

    % --- Check 5: injected transient is recovered at the expected location (AC3 spirit) ---
    windowStartFrame = nFrames - windowSamples + 1;
    expectedPeakIdx = injCenterFrame - windowStartFrame + 1;
    [peakVal, peakIdx] = max(offlineDff);
    baselineDff = median(offlineDff);
    peakLagSamples = peakIdx - expectedPeakIdx;
    assert(peakVal - baselineDff > 0.05, ...
        'Injected transient not recovered: peak-baseline=%.4f (expected > 0.05)', peakVal - baselineDff);
    assert(peakLagSamples >= -5 && peakLagSamples <= 30, ...
        'Recovered peak at sample %d, expected near %d (+causal filter lag), lag=%d', ...
        peakIdx, expectedPeakIdx, peakLagSamples);

    % --- Check 6: acqModeStart discards prior state (AC4) ---
    dff_on_acq_mode_start(struct(), struct());
    assert(isempty(mon.FrameBuffer) && isempty(mon.TraceBuffer), 'FrameBuffer/TraceBuffer not cleared on new acqModeStart');
    assert(mon.NFilled == 0 && mon.WritePtr == 0, 'NFilled/WritePtr not reset on new acqModeStart');

    % --- Cleanup ---
    if ~isempty(mon.Viewer) && isvalid(mon.Viewer) && isvalid(mon.Viewer.Figure)
        close(mon.Viewer.Figure);
    end
    dff_monitor_instance('clear');

    fprintf('\n=== Synthetic validation: ALL CHECKS PASSED ===\n');
    fprintf('seed=%d, fps=%g, windowSamples=%d, nFrames=%d\n', seed, fps, windowSamples, nFrames);
    fprintf('trace reconstruction maxAbsDiff = %.3g (tol 1e-6)\n', traceMaxAbsDiff);
    fprintf('live-vs-offline dff maxAbsDiff  = %.3g (tol 1e-6)\n', dffMaxAbsDiff);
    fprintf('injected transient: center=frame %d, amplitude=%g, sigma=%g frames\n', ...
        injCenterFrame, injAmplitude, injSigmaFrames);
    fprintf('recovered peak: sample %d (expected ~%d), value=%.4f, baseline=%.4f, lag=%d samples\n', ...
        peakIdx, expectedPeakIdx, peakVal, baselineDff, peakLagSamples);
end
