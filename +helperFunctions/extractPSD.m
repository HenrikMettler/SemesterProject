function [sessions] = extractPSD(sessions,windowLength,externalWindowShift,psdWindowShift, samplingRate,movingAverageLength,spectrogramFrequencies)
    for idxSession = 1:size(sessions,2)
        currentData = sessions{idxSession}.DATA'; % proc_spectrogram requires data in form: [Samples] x [Channels]

        % Compute fast spectrogram
        [psd, freqgrid] = proc_spectrogram(currentData, windowLength, externalWindowShift, psdWindowShift, samplingRate,movingAverageLength);
        psd = log(psd);

        % Selecting desired frequencies 
        [freqs, idfreqs] = intersect(freqgrid,spectrogramFrequencies);
        psd = psd(:, idfreqs, :);

        % Event alignement and subsampling
        cevents     = sessions{idxSession}.EVENT;
        events.TYP = cevents.TYP;
        positions = proc_pos2win(cevents.POS, externalWindowShift*samplingRate, 'backward', movingAverageLength*samplingRate); % I don't really know what happens, here but I trust Bastien ;)
        events.POS = positions;

        % Save structure for each run
        sessions{idxSession}.EVENT = events;
        sessions{idxSession}.FREQ = freqs;
        sessions{idxSession}.DATA = permute(psd,[3 2 1]); % return session with data in 3D (a new dimension for frequency!)
        sessions{idxSession}.SR = 1/externalWindowShift;
    end
end

