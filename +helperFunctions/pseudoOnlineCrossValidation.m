function [class_error_training,pseudoOnlineClassLabels,pseudoOnlineScore] = pseudoOnlineCrossValidation(dataStruct,pseudoOnlineFeatures, classifierParameters,pseudoOnlineTrueLabels)

% some data preparation
featureMatrix = dataStruct.featMat_allTrials;
trueLabels = dataStruct.trueLabels;
numFeat = classifierParameters.numFeat;
numFolds = classifierParameters.numFolds;
numTrials = size(dataStruct.featMat,3);
numTrainingPoints = size(dataStruct.featMat,2);
numOnlinePoints = size(pseudoOnlineFeatures,1)/numTrials;
numTestTrialsPerFold = floor(numTrials/numFolds); % floor - ugly hack if numTrials is not a multiple of numFolds

fisherIndNumFeat = dataStruct.fisherInd(1:numFeat);
featureMatrix = featureMatrix(:,fisherIndNumFeat);
pseudoOnlineFeatures = pseudoOnlineFeatures(:,fisherIndNumFeat);



for idxFold = 1:numFolds
    
    % trials for testing, training
    allIndex = 1:numTrials*numTrainingPoints;
    testIndex = (1+numTestTrialsPerFold*(idxFold-1)*numTrainingPoints:numTrainingPoints*numTestTrialsPerFold*idxFold);
    trainIndex = setdiff(allIndex, testIndex);
    pseudoOnlineIndex = (1+numTestTrialsPerFold*(idxFold-1)*numOnlinePoints:numOnlinePoints*numTestTrialsPerFold*idxFold);
    
    % labels
    trainLabel = trueLabels(trainIndex);
    
    % matrices with train / test data
    trainMatrix = featureMatrix(trainIndex,:);
    pseudoOnlineTestMatrix = pseudoOnlineFeatures(pseudoOnlineIndex,:);
   
    % normalize the data
    [trainMatrix,meanTrain,stdTrain] = zscore(trainMatrix);
    pseudoOnlineTestMatrix = (pseudoOnlineTestMatrix-meanTrain)./stdTrain;
    
    classifier_linear = fitcdiscr(trainMatrix,trainLabel,'DiscrimType',classifierParameters.type);
    %predict label for both training and testing and save class errors
    yhat_linear_Training  = predict(classifier_linear,trainMatrix);
    [pseudoOnlineClassLabels{idxFold},pseudoOnlineScore{idxFold}]  = predict(classifier_linear,pseudoOnlineTestMatrix);
    class_error_training(idxFold) = helperFunctions.classerror(trainLabel, yhat_linear_Training);
    

end
end



