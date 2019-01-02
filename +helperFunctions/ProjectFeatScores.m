function [fisherScores] = projectFeatScores(allFeatures,fisherInd,fisherPower)
    featuresScores = zeros(1,size(allFeatures,2));
    for i = 1:size(allFeatures,2)
        F_ind = find(fisherInd == i);
        featuresScores(i) = fisherPower(F_ind);
    end

    %got to a new line (channels) every 19 values (frequencies) in order to
    %project into channel x freqeuncie spaces
    numChannels = 16; % hard-coded
    numFreq = size(allFeatures,2)/numChannels;
    fisherScores = zeros(16,numFreq);
    for ch = 1:numChannels
        fisherScores(ch,:) = featuresScores(1,(numFreq*(ch-1))+1:1:(numFreq*(ch)));
    end

end

