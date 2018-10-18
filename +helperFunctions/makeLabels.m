function [trueLabels,labelPerTrial] = makeLabels(stopWindow,methodParam,frameShift,numTrials)

zeroLabels =  zeros(floor(frameShift*(abs(stopWindow(1))-methodParam.windowSize)),1);
oneLabels = ones(floor(frameShift*(stopWindow(2)-methodParam.windowSize)),1);
labelPerTrial = [zeroLabels;oneLabels];
trueLabels = [];
for idxTrial = 1:numTrials
    trueLabels = [trueLabels;labelPerTrial];
end

end

