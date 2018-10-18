function [class_error_training,class_error_testing,x,y,auc,c] = crossValidation(featureMatrix,trueLabels,type,fold,r,c)

% initialize some parameters to speed up the code
class_error_training = zeros(1,fold);
class_error_testing = zeros(1,fold);
x = [];
y = [];
auc = [];
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
        auc = [auc; A];
    end
    if ~isempty(c)
        cmat = confusionmat(TestingLabels',yhat_linear_Test);
        c(:,:,idxFold) = cmat/sum(sum(cmat));
    end
end
end

