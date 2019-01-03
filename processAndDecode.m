function processAndDecode(data,classifierType,psdMode,psdParam,windowParam,chanlocs16,saveFlag,testPerson,verbose)
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
    pseudoOnlineClass = figure(3);
    helperFunctions.plotPseudoOnlineClassification(pseudoOnlineScore,windowParam.pseudoOnlineWindow,psdParam);
    
end

%% save figures and variables
saveFigures = saveFlag(1);
if saveFigures == 1
    
    % figure path
    figPath = strcat('../figures/',testPerson);
    
    % generate figure names
    switch psdMode
        case 'multitaper'
            featDiscrimMapName =...
                strcat('FDMap_classifierType_',classifierType,'_psd_mode_',psdMode,...
                '_nTaper_ ',num2str(psdParam.numberOfTappers),'_windSize_',strrep(num2str(psdParam.windowSize),'.',','));
            featSelectName = strcat('FSel_classifierType_',classifierType,'_psd_mode_',psdMode,...
                '_nTaper_ ',num2str(psdParam.numberOfTappers),'_windSize_',strrep(num2str(psdParam.windowSize),'.',','));
            
            pseudoOnlineClassName = strcat('POn_classifierType_',classifierType,'_psd_mode_',psdMode,...
                '_nTaper_ ',num2str(psdParam.numberOfTappers),'_windSize_',strrep(num2str(psdParam.windowSize),'.',','));
            
        case 'pWelch'
            featDiscrimMapName =...
                strcat('FDMap_classifierType_',classifierType,'_psd_mode_',psdMode,...
                '_windSize_',strrep(num2str(psdParam.windowSize),'.',','));
            featSelectName = strcat('FSel_classifierType_',classifierType,'_psd_mode_',psdMode,...
                '_windSize_',strrep(num2str(psdParam.windowSize),'.',','));
            pseudoOnlineClassName = strcat('POn_classifierType_',classifierType,'_psd_mode_',psdMode,...
                '_windSize_',strrep(num2str(psdParam.windowSize),'.',','));
        otherwise
            error('psdMode not defined');
    end    
    saveas(featDiscrimMap,fullfile(figPath,featDiscrimMapName),'fig')
    saveas(featDiscrimMap,fullfile(figPath,featDiscrimMapName),'pdf')
    saveas(featDiscrimMap,fullfile(figPath,featDiscrimMapName),'png')
    saveas(featSelect,fullfile(figPath,featSelectName),'fig')
    saveas(featSelect,fullfile(figPath,featSelectName),'pdf')
    saveas(featSelect,fullfile(figPath,featSelectName),'png')
    
    saveas(pseudoOnlineClass,fullfile(figPath,pseudoOnlineClassName),'fig')
    saveas(pseudoOnlineClass,fullfile(figPath,pseudoOnlineClassName),'pdf')
    saveas(pseudoOnlineClass,fullfile(figPath,pseudoOnlineClassName),'png')
    
end

close all

%% saving variables
saveVariables = saveFlag(2);
if saveVariables == 1
    
    dataPath = strcat('../data/',testPerson);
    % generate file name
    switch psdMode
        case 'multitaper'
            currentFilename = strcat('Classifier_type_',classifierType,'_psd_mode_',psdMode,...
                '_windowSize_',num2str(psdParam.windowSize),'_nTapers_',num2str(psdParam.numberOfTappers),'.mat');
        case 'pWelch'
            currentFilename = strcat('Classifier_type_',classifierType,'_psd_mode_',psdMode,...
                '_windowSize_',num2str(psdParam.windowSize),'.mat');
        otherwise
            error('psdMode not defined');
    end
    
    
    save(fullfile(dataPath,currentFilename),'classifierType','classError','data','featMat','featMatPseudoOnline',...
        'fisherInd','fisherPower','pseudoOnlineScore','psdMode','psdParam','windowParam');
end


end

