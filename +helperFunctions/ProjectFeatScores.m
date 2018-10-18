function [fisherScores] = projectFeatScores(allFeatures,fisherInd,fisherPower,spectrogramFrequencies,numChannels)
    featuresScores = zeros(1,size(allFeatures,2));
    for i = 1:size(allFeatures,2)
        F_ind = find(fisherInd == i);
        featuresScores(i) = fisherPower(F_ind);
        %putting corresponding scores in right order compared to our features
    end

    %got to a new line (channels) every 19 values (frequencies) in order to
    %project into channel x freqeuncie spaces
    s = size(spectrogramFrequencies,2);
    fisherScores = zeros(numChannels,s);
    for ch = 1:numChannels
        fisherScores(ch,:) = featuresScores(1,(s*(ch-1))+1:1:(s*(ch)));
    end

end

