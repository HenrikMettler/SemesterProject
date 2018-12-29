function [class_error_training,class_error_testing] = OldcrossValidation(featureMatrix,trueLabels,type,fold)

% initialize some parameters to speed up the code
class_error_training = zeros(1,fold);
class_error_testing = zeros(1,fold);
s = size(featureMatrix,1)/fold;

for idxFold = 1:fold
    
    %index for testing, training
    allIndex = 1:size(featureMatrix,1);
    testIndex = ((idxFold-1)*s+1:idxFold*s);
    trainIndex = setdiff(allIndex, testIndex);
    
    % matrices with train / test data
    trainMatrix = featureMatrix(trainIndex,:);
    testMatrix = featureMatrix(testIndex,:,:);
     % train and test labels
    trainLabels = trueLabels(trainIndex,:);
    testLabels = trueLabels(testIndex,:);
    
    % normalize the data 
    [trainMatrix,meanTrain,stdTrain] = zscore(trainMatrix);
    testMatrix = (testMatrix-meanTrain)./stdTrain;
    

    classifier_linear = fitcdiscr(trainMatrix,trainLabels,'DiscrimType',type);
    %predict label for both training and testing and save class errors
    yhat_linear_Training  = predict(classifier_linear,trainMatrix);
    [yhat_linear_Test,~]  = predict(classifier_linear,testMatrix);
    class_error_training(idxFold) = helperFunctions.classerror(trainLabels, yhat_linear_Training);
    class_error_testing(idxFold) = helperFunctions.classerror(testLabels, yhat_linear_Test);
    

end
end
