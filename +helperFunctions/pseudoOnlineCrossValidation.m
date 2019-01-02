function [classErrorTraining,pseudoOnlineClassLabels,pseudoOnlineScore] = ...
    pseudoOnlineCrossValidation(featMat,featMatPseudoOnline,trueLabel,pseudoOnlineTrueLabel,fisherInd,classifierType,numFeat)
%(dataStruct,pseudoOnlineFeatures, classifierParameters,pseudoOnlineTrueLabels)

% parameters & data preparation
numFolds = 10;
numTrainingSamples = size(featMat,1);
numOnlineSamples = size(featMatPseudoOnline,1);

fisherIndNumFeat = fisherInd(1:numFeat);
featMat = featMat(:,fisherIndNumFeat);
featMatPseudoOnline = featMatPseudoOnline(:,fisherIndNumFeat);


for idxFold = 1:numFolds
    
    % trials for testing, training
    allIndex = 1:numTrainingSamples;
    testIndex = (1+(idxFold-1)/numFolds*numTrainingSamples:numTrainingSamples*idxFold/numFolds);
    trainIndex = setdiff(allIndex, testIndex);
    pseudoOnlineIndex = (1+(idxFold-1)/numFolds*numOnlineSamples:numOnlineSamples*idxFold/numFolds);
    
    % labels
    trainLabel = trueLabel(trainIndex);
    
    % matrices with train / test data
    trainMatrix = featMat(trainIndex,:);
    pseudoOnlineTestMatrix = featMatPseudoOnline(pseudoOnlineIndex,:);
   
    % normalize the data
    [trainMatrix,meanTrain,stdTrain] = zscore(trainMatrix);
    pseudoOnlineTestMatrix = (pseudoOnlineTestMatrix-meanTrain)./stdTrain;
    
    classifier = fitcdiscr(trainMatrix,trainLabel,'DiscrimType',classifierType);
    %predict label for both training and testing and save class errors
    yhatTraining  = predict(classifier,trainMatrix);
    [pseudoOnlineClassLabels{idxFold},pseudoOnlineScore{idxFold}]  = predict(classifier,pseudoOnlineTestMatrix);
    classErrorTraining(idxFold) = helperFunctions.classerror(trainLabel, yhatTraining);
    

end
end



