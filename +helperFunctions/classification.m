function [trainError,testError,pseudoOnlineClassification,classifier] = classification (featureMatrix,pseudoOnlineMatrix,trueLabels,classifierParam)
% Offline and PseudoOnline classification using the given parameters in
% classifier parameters

% extract some variables
numFolds = classifierParam.numFolds;
type = classifierParam.type;
numOfflineWindows = size(featureMatrix,1);
numOnlineWindows = size(pseudoOnlineMatrix,1);
numTrials = size(featureMatrix,2);
testTrialsPerFold = numTrials/numFolds;
allIndices = 1:numTrials;

trueLabelsAllTrials = [];
for idxTrial =1:numTrials
    trueLabelsAllTrials = [trueLabelsAllTrials;trueLabels];
end
trueLabelsAllTrain = trueLabelsAllTrials(1:(numFolds-1)/numFolds*size(trueLabelsAllTrials,1));
trueLabelsAllTest = trueLabelsAllTrials(1:1/numFolds*size(trueLabelsAllTrials,1));

numFeat = 10; % dummy

for idxFold = 1:numFolds
    %% seperate train and test data
    testIndices = (1+testTrialsPerFold*(idxFold-1):testTrialsPerFold*idxFold);    
    trainIndices = setdiff(allIndices,testIndices);
    
    trainData = featureMatrix(:,trainIndices,:);
    testData = featureMatrix(:,testIndices,:);    
    %% normalize the data  
    % change to 2dim
    [trainData2dim,size2train] = make2dim(trainData);
    [testData2dim,size2test] = make2dim(testData);
    % normalize the 2dim data
    [trainData2dim,meanTrain,stdTrain] = zscore(trainData2dim);
    testData2dim = (testData2dim-meanTrain)./stdTrain;
    % reconvert to 3dim
    trainData = make3dim(trainData2dim,size2train);
    testData = make3dim(testData2dim,size2test);

    %% calculate fisher scores and extract relevant data
    [fisherInd, ~] = helperFunctions.rankfeat(trainData2dim,trueLabelsAllTrain, 'fisher');
    
    trainData = trainData(:,:,fisherInd(1:numFeat)); % where do we choose the feature number? 
    trainData2dim = trainData2dim(:,fisherInd(1:numFeat));
    
    testData = testData(:,:,fisherInd(1:numFeat));
    testData2dim = testData2dim(:,fisherInd(1:numFeat));
    
    %% build model
    classifier{idxFold} = fitcdiscr(trainData2dim,trueLabelsAllTrain,'DiscrimType',type);
    
    % predict labels & calculate errors
    trainPred = predict(classifier{idxFold},trainData2dim);
    testPred = predict(classifier{idxFold},testData2dim);
    
    trainError(idxFold) = helperFunctions.classerror(trueLabelsAllTrain,trainPred);
    testError(idxFold) = helperFunctions.classerror(trueLabelsAllTest,testPred);
    
    % calcultate pseudonline class
    for idxOnlineWindow = 1:numOnlineWindows
        % extract data
        pseudoOnlineData = squeeze(pseudoOnlineMatrix(idxOnlineWindow,testIndices,:));
        
        % normalize (using training means)
        pseudoOnlineData =(pseudoOnlineData-meanTrain)./stdTrain;
        
        % extract highest ranked feat
        pseudoOnlineData = pseudoOnlineData(:,fisherInd(1:numFeat));
        
        % predict
        [pseudoOnlinePred(testIndices,idxOnlineWindow),pseudoOnlineScore(testIndices,idxOnlineWindow,:)] = predict(classifier{idxFold},pseudoOnlineData);
        
    end

end
% prepare data output
pseudoOnlineClassification.score = pseudoOnlineScore;
pseudoOnlineClassification.prediction = pseudoOnlinePred;

end


function [data2dim,size2] = make2dim(data3dim)
data2dim = [];
size2 = size(data3dim,2);
for idx2nddim = 1:size2
    data2dim=[data2dim;squeeze(data3dim(:,idx2nddim,:))];
end
end

function data3dim = make3dim(data2dim,size2)
data3dim=[];
size1 = size(data2dim,1)/size2;
for idx2=1:size2
    data3dim(:,idx2,:) = data2dim(1+(idx2-1)*size1:idx2*size1,:);
end
end


%     % normalize the data
%     [~,meanTrain2D,stdTrain2D] = zscore(trainData);
%     [~,meanTrain,asdf] = zscore(meanTrain2D); 
%     testData = (testData-meanTrain)./stdTrain;


% %index for testing, training
%     allIndex = 1:size(featureMatrix,1);
%     testIndex = ((idxFold-1)*s+1:idxFold*s);
%     trainIndex = setdiff(allIndex, testIndex);
%     
%     % matrices with train / test data
%     trainMatrix = featureMatrix(trainIndex,:);
%     testMatrix = featureMatrix(testIndex,:,:);
%      % train and test labels
%     trainLabels = trueLabels(trainIndex,:);
%     testLabels = trueLabels(testIndex,:);
%     
%     % normalize the data 
%     [trainMatrix,meanTrain,stdTrain] = zscore(trainMatrix);
%     testMatrix = (testMatrix-meanTrain)./stdTrain;
%     
% 
%     classifier_linear = fitcdiscr(trainMatrix,trainLabels,'DiscrimType',type);
%     %predict label for both training and testing and save class errors
%     yhat_linear_Training  = predict(classifier_linear,trainMatrix);
%     [yhat_linear_Test,~]  = predict(classifier_linear,testMatrix);
%     class_error_training(idxFold) = helperFunctions.classerror(trainLabels, yhat_linear_Training);
%     class_error_testing(idxFold) = helperFunctions.classerror(testLabels, yhat_linear_Test);
%     