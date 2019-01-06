function [rfModels,trainError,testError,optNumFeat,minInd] = randomForestClassification(featMat,trueLabel,numTreesArray,trainFract)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here

%% split the data
numElement = size(featMat,1);
numTrain = ceil(trainFract*numElement);
% numTest = numElement - numTrain;

trainData = featMat(1:numTrain,:);
testData = featMat(numTrain+1:end,:);

trainLabel = trueLabel(1:numTrain);
testLabel = trueLabel(numTrain+1:end);


%% create the models & calculate the errors

for idxNumTree = 1:size(numTreesArray,2)
    currentNumTree = numTreesArray(idxNumTree);
    rfModels{idxNumTree} = TreeBagger(currentNumTree,trainData,trainLabel);
    [currentTrainPred,~] = predict(rfModels{idxNumTree},trainData);
    [currentTestPred,~] = predict(rfModels{idxNumTree},testData);
    
    currentTrainPred = cell2mat(currentTrainPred);
    currentTestPred = cell2mat(currentTestPred);
    
    trainPred(:,idxNumTree) = str2num(currentTrainPred);
    testPred(:,idxNumTree) = str2num(currentTestPred);

    trainError(idxNumTree) = helperFunctions.classerror(trainLabel,trainPred(:,idxNumTree));
    testError(idxNumTree)  = helperFunctions.classerror(testLabel,testPred(:,idxNumTree));

end
        
%% calculate the optimal number of feat
[~,minInd] = min(testError);
optNumFeat = numTreesArray(minInd);

end

