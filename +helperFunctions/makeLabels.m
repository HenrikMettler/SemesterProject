function [TLabels, TLabelsPerTrials] = makeLabels(concatenatedStop,stopWindow,samplingRate,numTrials)
% basic concept:
% if tStop[i] + stopWindow[1] < 0 -> before stop -> motor
% Imagery -> label 1
% if tStop[i] + stopWindow[1] >= 0 -> after stop -> label 0

trueLabels = zeros(1,size(concatenatedStop,3));
for idxTime=1:size(trueLabels,2)
    if stopWindow(1) + idxTime/samplingRate - 0.5  < 0
        trueLabels(idxTime) = 1;
    end
end

TLabels = [];
TLabelsPerTrials = [];
for idxTrial = 1:numTrials
    TLabels = [TLabels, trueLabels];
    TLabelsPerTrials = [TLabelsPerTrials; trueLabels];
end

