% load data example
dataPath = '../data/ak3';
dataFile = 'testPerson_ak3_mtWindowSize_0.75_nTapers_8_classifier_type_diaglinear.mat';
dataLoaded = load (fullfile(dataPath,dataFile));

% prepare variables
featureMatrix = permute(dataLoaded.multitaper.featMat,[2,3,1]);
pseudoOnlineMatrix = permute(dataLoaded.pseudoOnlineFeatMat,[2,3,1]);
numSamplesPerTrial = size(featureMatrix,1);
trueLabels = [zeros(numSamplesPerTrial/2,1);ones(numSamplesPerTrial/2,1)];
classifierParam = dataLoaded.classifierParam;

% initialize classification
[trainingError,validationError,pseudoOnlineClassification,classifier] = helperFunctions.classification(featureMatrix,pseudoOnlineMatrix,trueLabels,classifierParam);


figure(1)
hold on;
imagesc(pseudoOnlineClassification.score(:,:,2))
titleStr = [dataLoaded.testPerson,' windowSize: ',num2str(dataLoaded.multitaperWindowSize),' classifier type: ',dataLoaded.classifierType];
title(titleStr)
holdOff
