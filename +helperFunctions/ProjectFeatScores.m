function [fisherScores] = ProjectFeatScores(allFeatures,fisherInd,fisherPower,spectrogramFrequencies,numChannels,runName,chanlocs16)
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
    % plot fisher score
    imagesc(spectrogramFrequencies, 1:16, fisherScores)
    t = ['Features discriminancy map based on Fisher score - subject: ' runName];
    title(t)
    xlabel ('Frequency [Hz]')
    ylabel ('Channel')
    set(gca,'yTick',1:16,'YTickLabel', {chanlocs16.labels})
    c = colorbar;
    c.Label.String = 'Fisher Score';
    caxis([0 0.30])
end

