function [trueLabel,labelPerTrial] = makeLabels(featMat3DZero,featMat3DOne)

numTrials = size(featMat3DZero,1);
zeroLabel = zeros(size(featMat3DZero,2),1);
oneLabel = ones(size(featMat3DOne,2),1);
labelPerTrial = vertcat(zeroLabel,oneLabel);
trueLabel = [];
for idxTrial = 1:numTrials
    trueLabel = [trueLabel;labelPerTrial];
end

end

