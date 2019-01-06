function [pseudoOnlineLabels,pseudoOnlineScore] = randomForestOnline(rfModel,featMatPseudoOnline)
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here

% predict labels and score for pseudoonline feature matrix
[pseudoOnlineLabels,pseudoOnlineScore] = predict(rfModel,featMatPseudoOnline);
pseudoOnlineLabels = cell2mat(pseudoOnlineLabels);
pseudoOnlineLabels = str2num(pseudoOnlineLabels);

end

