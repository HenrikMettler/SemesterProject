function  plotFisherScores(spectrogramFrequencies, fisherScores, imageTitle, channelLabels)
% PLOT THE FEATURE DISCRIMINANCY MAP BASED ON FISHER SCORE
%   using the spectrogram frequencies and a specific image title plots the 
%   feature discriminancy map, using imageTitle as a title for the plot

imagesc(spectrogramFrequencies, 1:16, fisherScores)
title(imageTitle)
xlabel ('Frequency [Hz]')
ylabel ('Channel')
set(gca,'yTick',1:16,'YTickLabel', channelLabels)
c = colorbar;
c.Label.String = 'Fisher Score';
caxis([0 0.30])

end

