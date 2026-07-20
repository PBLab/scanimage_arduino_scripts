function fps = si_get_frame_rate(hSI) %#ok<INUSD>
    % Adapter: returns the live scan frame rate in Hz.
  fps =hSI.hRoiManager.scanFrameRate;
end
