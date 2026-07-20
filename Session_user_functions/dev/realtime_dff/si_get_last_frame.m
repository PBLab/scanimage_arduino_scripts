function frame = si_get_last_frame(hSI, channelIdx) %#ok<INUSD>
    % Adapter: returns the most recently acquired frame for channelIdx.
    % Validated by PB
    frame = gpuArray(hSI.hDisplay.lastFrame{channelIdx});
end
