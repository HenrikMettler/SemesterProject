function classError = featureSelection(featureMatrix,fisherInd,trueLabels, classifierParam)
% PERFORMS FEATURE SELECTION
%
% Input Arguments
%   featureMatrix: NxD - matrix with N-samples and D-features
%   fisherInd: 1xD vector with features sorted accordingt to their
%   discriminative power
%   trueLabels: 1xN - vector with true label for every sample (1 = miStop, 0 = mI)
%   classifierParam: struct containing the following fields (Todo: adapt to diff. type of classifier?)
%       maxFeat: Scalar < D - maximal number of features that are tested
%       stepFeat: Scalar < maxFeat - step size in between number of features that are tested
%       type: classifier type (diaglinear, linear, diagquadratic, quadratic)
%       fold: param for the cross validation

%% Input Validation (To do)


%% parameters

% extract from classifier Param
maxFeat = classifierParam.maxFeat;
numClassifier = maxFeat;
type = classifierParam.type;
numFolds = classifierParam.numFolds;
%% do stuff


for idxClassifier = 1:numClassifier
    indexes = fisherInd(1:idxClassifier);%look for the first f best features
    currentFeatures = featureMatrix(:,indexes);%only the features selected
    [class_train_error_linear,class_test_error_linear,~] = ...
        helperFunctions.crossValidation(currentFeatures,trueLabels,type,numFolds,[],[]);
    testError(idxClassifier)= mean(class_test_error_linear);
    trainError(idxClassifier) = mean(class_train_error_linear);
    testErrorStd(idxClassifier) = std(class_test_error_linear);
    trainErrorStd(idxClassifier) = std(class_train_error_linear);
end

classError.trainError = trainError;
classError.trainErrorStd = trainErrorStd;
classError.testError = testError;
classError.testErrorStd = testErrorStd;

end

