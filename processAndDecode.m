function processAndDecode(data,classifierType,psdMode,psdParam,windowParam,chanlocs16,saveFlag,testPerson,verbose)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here

if isfield(data,'pseudoOnline')
    doPseudoOnline = 1;
else 
    doPseudoOnline = 0;
end

if verbose == 1
    disp('*** STARTED CALCULATING PSD ESTIMATES ***')
    disp(psdMode)
    disp(psdParam.windowSize)
end


%% CALCULATE PSD-ESTIMATES & CREATE FEATURE MATRIX

[psdEstimateZero,psdTimerZero] = helperFunctions.calculatePSD(data.offlineZero,psdMode,psdParam);
[psdEstimateOne,~] = helperFunctions.calculatePSD(data.offlineOne,psdMode,psdParam);

% create feature matrix
[~,featMat3DZero] = helperFunctions.makeFeatMat(psdEstimateZero); % featMat / featMat per Trial
[~,featMat3DOne] = helperFunctions.makeFeatMat(psdEstimateOne); % featMat / featMat per Trial
featMat3D= helperFunctions.convertFeatMat(featMat3DZero,featMat3DOne);
featMat = [];
for idxTrial = 1:size(featMat3D,1)
    featMat = [featMat,featMat3D(idxTrial,:,:)];
end
featMat = squeeze(featMat);

% create a true label vector
[trueLabel,~] = helperFunctions.makeLabels(featMat3DZero,featMat3DOne);

%% START CLASSIFICATION

switch classifierType 
    case 'randomForest'
        numTreesArray = [20,50,100,500,1000];
        trainFract = 0.8;
        [rfModels,trainError,testError,optNumFeat,minInd] = helperFunctions.randomForestClassification(featMat,trueLabel,numTreesArray,trainFract);
        classError = testError(minInd);
    otherwise % cases: 'diaglinear', 'linear'
        %% RANK FEATURES USING FISHER SCORE
        
        if verbose == 1
            disp('*** STARTED CALCULATING FISHER SCORE ***')
        end
        
        % rank the (normalized) features (using fisher method)
        featMatNormalized = zscore(featMat);
        [fisherInd, fisherPower] = helperFunctions.rankfeat(featMatNormalized,trueLabel', 'fisher');
        
        % project the fisher score onto a 2D image channel x frequency
        fisherScores = helperFunctions.projectFeatScores(featMatNormalized,fisherInd,fisherPower);
        featDiscrimMap = figure(1);
        helperFunctions.plotFisherScores(psdParam,fisherScores,psdMode,classifierType,{chanlocs16.labels})
        
        
        %% PERFORM AND PLOT FEATURE SELECTION
        
        if verbose == 1
            disp('*** STARTED FEATURE SELECTION ***')
        end
        
        classError = helperFunctions.featureSelection(featMat,fisherInd,trueLabel, classifierType);
        featSelect = figure(2);
        helperFunctions.plotFeatureSelection(classError,psdMode,psdParam,classifierType)
end
%% PSEUDOONLINE CLASSIFICATION

if doPseudoOnline == 1
    
    if verbose == 1
        disp('*** STARTED PSEUDOONLINE ***')
    end
    
    % extract psd & make feature matrix
    [psdEstimatePseudoOnline,~] = helperFunctions.calculatePSD(data.pseudoOnline,psdMode,psdParam);
    [featMatPseudoOnline,featMat3DPseudoOnline] = helperFunctions.makeFeatMat(psdEstimatePseudoOnline); % featMat / featMat per Trial
    switch classifierType
        case 'randomForest'
            [pseudoOnlineLabels,pseudoOnlineScore] = helperFunctions.randomForestOnline(rfModels{1,minInd},featMatPseudoOnline);
            % plot the pseudo online classification
            pseudoOnlineClass = figure(3);
            helperFunctions.plotRandomForestPseudoOnlineClassification(pseudoOnlineScore,windowParam.pseudoOnlineWindow,psdParam);
        otherwise
            
            numFeat = 5;
            
            % create a true label vector for the pseudo online
            pseudoOnlineTrueLabel = helperFunctions.createPseudoOnlineTrueLabel(windowParam,psdParam,featMat3DPseudoOnline);
            
            % perform cross-validation
            [~,~,pseudoOnlineScore] =...
                helperFunctions.pseudoOnlineCrossValidation...
                (featMat,featMatPseudoOnline,trueLabel,pseudoOnlineTrueLabel,fisherInd,classifierType,numFeat);
            % plot the pseudo online classification
            pseudoOnlineClass = figure(3);
            helperFunctions.plotPseudoOnlineClassification(pseudoOnlineScore,windowParam.pseudoOnlineWindow,psdParam);
            
    end
end

%% SAVE FIGURES
saveFigures = saveFlag(1);
if saveFigures == 1
    
    if verbose == 1
        disp('*** SAVING FIGURES ***')
    end
    
    
    % figure path
    figPath = strcat('../figures/',testPerson);
    switch classifierType

        case 'randomForest'
            switch psdMode
                case 'multitaper'
                     pseudoOnlineClassName = strcat('POn_classifierType_',classifierType,'_psd_mode_',psdMode,...
                    '_nTaper_ ',num2str(psdParam.numberOfTappers),'_windSize_',strrep(num2str(psdParam.windowSize),'.',','));
                case 'pWelch'
                     pseudoOnlineClassName = strcat('POn_classifierType_',classifierType,'_psd_mode_',psdMode,...
                    '_windSize_',strrep(num2str(psdParam.windowSize),'.',','));
                otherwise
            end
        otherwise
            
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
        
    end
    
    saveas(pseudoOnlineClass,fullfile(figPath,pseudoOnlineClassName),'fig')
    saveas(pseudoOnlineClass,fullfile(figPath,pseudoOnlineClassName),'pdf')
    saveas(pseudoOnlineClass,fullfile(figPath,pseudoOnlineClassName),'png')
end
close all

%% SAVE VARIABLES

saveVariables = saveFlag(2);
if saveVariables == 1
    
    if verbose == 1
        disp('*** SAVING VARIABLES ***')
    end
    
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
    
    switch classifierType
        case 'randomForest'
            save(fullfile(dataPath,currentFilename),'classifierType','classError','data','featMat','featMatPseudoOnline',...
                'pseudoOnlineScore','psdMode','psdParam','windowParam','psdTimerZero');
            
        otherwise
            save(fullfile(dataPath,currentFilename),'classifierType','classError','data','featMat','featMatPseudoOnline',...
                'fisherInd','fisherPower','pseudoOnlineScore','psdMode','psdParam','windowParam','psdTimerZero');
    end
end
    
   

end

