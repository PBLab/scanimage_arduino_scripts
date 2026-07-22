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
    % hRoiManager.linesPerFrame/pixelsPerLine are read directly by Reset() (not
    % via a faked adapter), so the stub must provide them matching H/W above.
    hSI = struct('note', 'synthetic placeholder — unused, adapters are faked', ...
        'hRoiManager', struct('linesPerFrame', H, 'pixelsPerLine', W));
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
    liveDff = gather(get(mon.Viewer.LineHandles(1), 'YData'))';
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
    % Reset() always reallocates FrameBuffer/TraceBuffer to fresh zero-filled
    % arrays (never to []), so AC4 is checked via content/state, not isempty.
    dff_on_acq_mode_start(struct(), struct());
    assert(all(gather(mon.FrameBuffer(:)) == 0), 'FrameBuffer not zero-reset on new acqModeStart');
    assert(all(gather(mon.TraceBuffer(:)) == 0), 'TraceBuffer not zero-reset on new acqModeStart');
    assert(mon.NFilled == 0 && mon.WritePtr == 0, 'NFilled/WritePtr not reset on new acqModeStart');

    % --- ROI extraction scenario (Stage 1 signal injection, CLAUDE.md §8) ---
    % Reuses the same monitor singleton, matching real usage: ROIs are drawn
    % while idle between acquisitions, then acqModeStart freezes them.
    roiDiag = test_roi_extraction(mon);

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
    fprintf('ROI_in peak-baseline=%.4f (expected >0.05), ROI_out peak-baseline=%.4f (expected <0.02)\n', ...
        roiDiag.inPeak, roiDiag.outPeak);
    fprintf('ROI trace reconstruction maxAbsDiff: in=%.3g, out=%.3g (tol 1e-6)\n', ...
        roiDiag.inTraceDiff, roiDiag.outTraceDiff);
end

function roiDiag = test_roi_extraction(mon)
    % Stage 1 (Signal Injection) extension covering per-ROI extraction
    % (CLAUDE.md §8): injects a transient confined to one spatial quadrant of
    % the frame, draws two disjoint ROIs on the live viewer (one covering the
    % injected region, one a disjoint control), and verifies the pipeline
    % recovers the transient only in the ROI that actually covers it. Also
    % checks mask caching, trace-matrix shape, and the lock/unlock-on-acqDone
    % behavior. Labeled synthetic per CLAUDE.md — generator kept versioned here
    % alongside the whole-FOV scenario, not thrown away.

    seed = 43;
    rng(seed);

    fps = 30;
    windowSeconds = 20;
    windowSamples = round(fps * windowSeconds);
    H = 16; W = 16;
    nFrames = 900;
    baseline = 200;
    pixelNoiseStd = 1.0;

    injCenterFrame = 800;
    injSigmaFrames = 15;
    injAmplitude = 60;

    % Injected region vs. a disjoint, uninjected control region.
    inRows = 1:8; inCols = 1:8;
    outRows = 9:16; outCols = 9:16;

    t = (1:nFrames)';
    injectedTimecourse = injAmplitude * exp(-0.5 * ((t - injCenterFrame) / injSigmaFrames).^2);

    frameStackDouble = baseline + pixelNoiseStd * randn(H, W, nFrames);
    for k = 1:nFrames
        frameStackDouble(inRows, inCols, k) = frameStackDouble(inRows, inCols, k) + injectedTimecourse(k);
    end
    frameStack = int16(round(frameStackDouble));

    groundTruthIn = squeeze(mean(mean(double(frameStack(inRows, inCols, :)), 1), 2));
    groundTruthOut = squeeze(mean(mean(double(frameStack(outRows, outCols, :)), 1), 2));

    assignin('base', 'testFrameStack', frameStack);
    assignin('base', 'testFps', fps);
    clear si_get_last_frame  % reset the fake's persistent frame index for the new stack

    % --- Draw two disjoint ROIs on the live viewer. Vertices span [n-0.5, n+0.5]
    % per pixel index, matching the poly2mask/extract_traces.m convention, so an
    % N-pixel span covers exactly rows/cols 1:N. ---
    ax = mon.Viewer.Axes_img;
    roiIn = drawpolygon(ax, 'Position', ...
        [inCols(1)-0.5, inRows(1)-0.5; inCols(end)+0.5, inRows(1)-0.5; ...
         inCols(end)+0.5, inRows(end)+0.5; inCols(1)-0.5, inRows(end)+0.5]);
    roiIn.Tag = 'ROI'; roiIn.Label = 'ROI_in'; roiIn.Color = [1 0 0];

    roiOut = drawpolygon(ax, 'Position', ...
        [outCols(1)-0.5, outRows(1)-0.5; outCols(end)+0.5, outRows(1)-0.5; ...
         outCols(end)+0.5, outRows(end)+0.5; outCols(1)-0.5, outRows(end)+0.5]);
    roiOut.Tag = 'ROI'; roiOut.Label = 'ROI_out'; roiOut.Color = [0 0 1];

    % --- acqModeStart: computes+caches masks, locks ROI editing ---
    dff_on_acq_mode_start(struct(), struct());

    assert(numel(mon.RoiMasks) == 2, 'Expected 2 cached ROI masks, got %d', numel(mon.RoiMasks));
    assert(size(mon.TraceBuffer, 2) == 2, 'TraceBuffer should have 2 columns in ROI mode, got %d', size(mon.TraceBuffer, 2));

    expectedInMask = false(H, W);
    expectedInMask(inRows, inCols) = true;
    expectedOutMask = false(H, W);
    expectedOutMask(outRows, outCols) = true;

    labels = {mon.RoiMasks.Label};
    inIdx = find(strcmp(labels, 'ROI_in'));
    outIdx = find(strcmp(labels, 'ROI_out'));
    assert(isequal(sort(mon.RoiMasks(inIdx).PixelIdx), find(expectedInMask)), ...
        'ROI_in cached mask does not match the drawn polygon''s expected pixels');
    assert(isequal(sort(mon.RoiMasks(outIdx).PixelIdx), find(expectedOutMask)), ...
        'ROI_out cached mask does not match the drawn polygon''s expected pixels');

    % --- Lock state: editing must be frozen while "running" ---
    assert(strcmp(mon.Viewer.AddRoiButton.Enable, 'off'), 'Add-ROI button should be disabled while streaming');
    assert(strcmp(roiIn.InteractionsAllowed, 'none') && ~roiIn.Deletable, 'ROI_in should be locked while streaming');
    assert(strcmp(roiOut.InteractionsAllowed, 'none') && ~roiOut.Deletable, 'ROI_out should be locked while streaming');

    for k = 1:nFrames
        dff_on_frame_acquired(struct(), struct());
    end

    % --- Trace reconstruction matches ground truth, per ROI ---
    liveTrace = gather(mon.currentTrace());
    windowStartFrame = nFrames - windowSamples + 1;
    expectedIn = groundTruthIn(windowStartFrame:nFrames);
    expectedOut = groundTruthOut(windowStartFrame:nFrames);

    inDiff = max(abs(liveTrace(:, inIdx) - expectedIn));
    outDiff = max(abs(liveTrace(:, outIdx) - expectedOut));
    assert(inDiff < 1e-6, 'ROI_in trace diverges from ground truth: maxAbsDiff=%.3g', inDiff);
    assert(outDiff < 1e-6, 'ROI_out trace diverges from ground truth: maxAbsDiff=%.3g', outDiff);

    % --- Recovered transient: present in ROI_in, absent in ROI_out ---
    dffParams = dff_default_params().dffParams;
    dffIn = gather(dff_calc(gpuArray(expectedIn), fps, dffParams.tau_0, dffParams.tau_1, dffParams.tau_2, dffParams.invert));
    dffOut = gather(dff_calc(gpuArray(expectedOut), fps, dffParams.tau_0, dffParams.tau_1, dffParams.tau_2, dffParams.invert));

    inPeak = max(dffIn) - median(dffIn);
    outPeak = max(dffOut) - median(dffOut);
    assert(inPeak > 0.05, 'ROI_in should recover the injected transient: peak-baseline=%.4f (expected > 0.05)', inPeak);
    assert(outPeak < 0.02, 'ROI_out should NOT show the injected transient: peak-baseline=%.4f (expected < 0.02)', outPeak);

    % --- acqDone: unlocks ROI editing ---
    dff_realtime_cleanup(struct(), struct());
    assert(strcmp(mon.Viewer.AddRoiButton.Enable, 'on'), 'Add-ROI button should be re-enabled after acqDone');
    assert(strcmp(roiIn.InteractionsAllowed, 'all') && roiIn.Deletable, 'ROI_in should be unlocked after acqDone');
    assert(strcmp(roiOut.InteractionsAllowed, 'all') && roiOut.Deletable, 'ROI_out should be unlocked after acqDone');

    delete(roiIn);
    delete(roiOut);

    roiDiag = struct('inPeak', inPeak, 'outPeak', outPeak, 'inTraceDiff', inDiff, 'outTraceDiff', outDiff);
end
