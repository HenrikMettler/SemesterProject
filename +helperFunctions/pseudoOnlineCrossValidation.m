function [outputArg1,outputArg2] = pseudoOnlineCrossValidation(trainFeatures,pseudoOnlineFeatures, classifierParameters)

numFolds = classifierParameters.numFolds;
numTrials = size(trainFeatures,3);
numTestTrialsPerFold = floor(numTrials/numFolds); % floor - ugly hack if numTrials is not a multiple of numFolds

for idxFold = 1:numFolds
    
    % trials for testing, training
    allIndex = 1:size(trainFeatures,3);
    testIndex = (1+numTestTrialsPerFold*(idxFold-1):numTestTrialsPerFold*idxFold);
    trainIndex = setdiff(allIndex, testIndex);
    
    % matrices with train / test data
    trainMatrix = trainFeatures(:,:,trainIndex);
    testMatrix = trainFeatures(:,:,testIndex);
    pseudoOnlineTestMatrix = pseudoOnlineFeatures(:,:,testIndex);
    
    % train and test labels
    trainLabels = trueLabels(trainIndex,:);
    testLabels = trueLabels(testIndex,:);

    
    classifier_linear = fitcdiscr(trainMatrix,trainLabels,'DiscrimType',type);
    %predict label for both training and testing and save class errors
    yhat_linear_Training  = predict(classifier_linear,trainMatrix);
    [yhat_linear_Test,score]  = predict(classifier_linear,testMatrix);
    class_error_training(idxFold) = helperFunctions.classerror(trainLabels, yhat_linear_Training);
    class_error_testing(idxFold) = helperFunctions.classerror(testLabels, yhat_linear_Test);
    
    if ~isempty(r)
        [FPR,TPR,~,A] = perfcurve(TestingLabels,score(:,2),1);
        x = [x,FPR];
        y = [y,TPR];
        % auc = [auc; A];
    end
    if ~isempty(c)
        cmat = confusionmat(TestingLabels',yhat_linear_Test);
        c(:,:,idxFold) = cmat/sum(sum(cmat));
    end
end
end





