function processAndDecode(data,classifierType,psdMode,psdParam,windowParam,chanlocs16,saveFlag,verbose)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here

if isfield(data,'pseudoOnline')
    doPseudoOnline = 1;
else 
    doPseudoOnline = 0;
end

% calculate psd - estimates
[psdEstimateZero,psdTimerZero] = helperFunctions.calculatePSD(data.offlineZero,psdMode,psdParam);
[psdEstimateOne,psdTimerOne] = helperFunctions.calculatePSD(data.offlineOne,psdMode,psdParam);

% create feature matrix
[~,featMat3DZero] = helperFunctions.makeFeatMat(psdEstimateZero); % featMat / featMat per Trial
[~,featMat3DOne] = helperFunctions.makeFeatMat(psdEstimateOne); % featMat / featMat per Trial
featMat3D= helperFunctions.convertFeatMat(featMat3DZero,featMat3DOne);
featMat = [];
for idxTrial = 1:size(featMat3D,1)
    featMat = [featMat,featMat3D(idxTrial,:,:)];
end
featMat = squeeze(featMat);

% if doPseudoOnline == 1
%     [psdEstimatePseudoOnline,psdTimerPseudoOnline] = helperFunctions.calculatePSD(data.pseudoOnline,psdMode,psdParam);
%     [featMatPseudoOnline,featMat3DPseudoOnline] = helperFunctions.makeFeatMat(psdEstimatePseudoOnline); % featMat / featMat per Trial
% end

% create a true label vector
[trueLabel,labelPerTrial] = helperFunctions.makeLabels(featMat3DZero,featMat3DOne);

% rank the (normalized) features (using fisher method)
featMatNormalized = zscore(featMat);
[fisherInd, fisherPower] = helperFunctions.rankfeat(featMatNormalized,trueLabel', 'fisher');

% project the fisher score onto a 2D image channel x frequency
fisherScores = helperFunctions.projectFeatScores(featMatNormalized,fisherInd,fisherPower);
featDiscrimMap = figure(1);
helperFunctions.plotFisherScores(psdParam,fisherScores,psdMode,classifierType,{chanlocs16.labels})

% perform and plot feature selection for both decoder
classError = helperFunctions.featureSelection(featMat,fisherInd,trueLabel, classifierType);
featSelect = figure(2);
helperFunctions.plotFeatureSelection(classError,psdMode,psdParam,classifierType)

%% pseudo online classification 
if doPseudoOnline == 1
    % extract psd & make feature matrix
    [psdEstimatePseudoOnline,psdTimerPseudoOnline] = helperFunctions.calculatePSD(data.pseudoOnline,psdMode,psdParam);
    [featMatPseudoOnline,featMat3DPseudoOnline] = helperFunctions.makeFeatMat(psdEstimatePseudoOnline); % featMat / featMat per Trial
    
    numFeat = 5; % AUTOMATE THIS DECISION
   
    % create a true label vector for the pseudo online
    pseudoOnlineTrueLabel = helperFunctions.createPseudoOnlineTrueLabel(windowParam,psdParam,featMat3DPseudoOnline);
   
    % perform cross-validation
    [~,pseudoOnlineClassLabels,pseudoOnlineScore] =...
        helperFunctions.pseudoOnlineCrossValidation...
        (featMat,featMatPseudoOnline,trueLabel,pseudoOnlineTrueLabel,fisherInd,classifierType,numFeat);
    % plot the pseudo online classification
    figure(3)
    helperFunctions.plotPseudoOnlineClassification(pseudoOnlineScore,pseudoOnlineWindow,multitaperWindowSize);
    
end

%% save figures and variables

end

