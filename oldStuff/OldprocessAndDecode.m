%% MULTITAPER SIGNAL PROCESSING IMPLEMENTATION

% % add paths & load general data
% addpath(genpath('../rsc')) % path to data and common functions
% 
% load('channel_location_16_10-20_mi.mat') % struct containing info about the eeg channels
% load('laplacian_16_10-20_mi.mat') % data matrix for laplacian filtering
% 
% %% DEFINABLE VARIABLES -> now in main.m
% 
% testPerson = 'ak3'; % options: 'ak2','ak3'
% multitaperWindowSize = 1; % "meaningful" options: 1,0.5,0.25
% numberOfTappers = 4; % try 3:8
% classifierType = 'diaglinear'; % options (to be defined) 
% saveFigures = 1; % boolean

%%
switch testPerson
    case 'ak2'
        dataPath = '../rsc/DataFiles/runs_ak2';
    case 'ak3'
        dataPath = '../rsc/DataFiles/runs_ak3';
    otherwise
        error('This subject is not available');
end

files = dir(fullfile(dataPath,'*.gdf'));
currentFilename = {files.name};



%% set parameters

samplingRate = 512;
numChannels = 16;
numTrials = 120;

% psd estimate params - common for all methods
frameShift = 16; % [Herz] -> freq for psd windows

% multitaper parameters - in one struct
multitaperParam.windowSize = multitaperWindowSize;
multitaperParam.numberOfTappers = numberOfTappers;
multitaperParam.frequencyRange = 4:1/multitaperParam.windowSize:40;

% pwelch parameters - in one struct
pwelchParam.psdWindow = 0.5*samplingRate;
pwelchParam.psdNOverlap = 0.25*samplingRate;
pwelchParam.frequencyRange = 4:2:40;
pwelchParam.windowSize = 1;

% epoching parameters
miParam.Id = 400; 
miParam.window = [-2,2];
stopParam.Id = 555;
stopParam.window = [-2,2];

pseudoOnlineWindow = [-4,6]; % window for pseudoonline class: note class starts at t(1) + windowSize


% spatial filtering parameters 
order = 4;
spat_type = 'CAR';

% classifier parameters 
classifierParam.type = classifierType;
classifierParam.maxFeat = 30;
classifierParam.numFolds = 10;


%% preprocess data

% create a sessions array
sessions = helperFunctions.createSessions(currentFilename,chanlocs16);

% spatial filtering
for idxSession = 1:size(sessions,2)
    sessions{idxSession}.DATA = helperFunctions.spatFilter(sessions{idxSession}.DATA, spat_type, lap, numChannels);
end

% create epochs around MI-Init and MI-Term
[epochMotorImagery,epochStop] = helperFunctions.epochSessions(sessions, miParam.Id, miParam.window,stopParam.Id, stopParam.window);

% concatenate data from diff session for every epoch
[concatenatedMotorImagery,concatenatedStop] = helperFunctions.concatSessions(epochMotorImagery,epochStop);

% split concatenated stop into zero / one segments
concatenatedStopZeros = concatenatedStop(:,:,1:-stopParam.window(1)*samplingRate);
concatenatedStopOnes = concatenatedStop(:,:,-stopParam.window(1)*samplingRate+1:end);

%% calculate psd - estimates

[multitaperZero_pxx,multitaperZero_timer] = helperFunctions.calculatePSD(concatenatedStopZeros,'multitaper',multitaperParam,frameShift,samplingRate);
[multitaperOne_pxx,multitaperOne_timer] = helperFunctions.calculatePSD(concatenatedStopOnes,'multitaper',multitaperParam,frameShift,samplingRate);

if doPwelch == 1
    [pwelchZero_pxx,pwelchZero_timer] = helperFunctions.calculatePSD(concatenatedStopZeros,'pwelch',pwelchParam,frameShift,samplingRate);
    [pwelchOne_pxx,pwelchOne_timer] = helperFunctions.calculatePSD(concatenatedStopOnes,'pwelch',pwelchParam,frameShift,samplingRate);
    pwelch.pxx = cat(2,pwelchZero_pxx,pwelchOne_pxx);
    
end

multitaper.pxx = cat(2,multitaperZero_pxx,multitaperOne_pxx);


% rank the features (currently fisher method is used)
[multitaper.fisherInd, multitaper.fisherPower] = helperFunctions.rankfeat(multitaper.featMat_allTrials,multitaper.trueLabels, 'fisher');


% project the fisher score onto a 2D image channel x frequency
multitaper.fisherScores = helperFunctions.projectFeatScores(multitaper.featMat_allTrials,...
    multitaper.fisherInd,multitaper.fisherPower,multitaperParam.frequencyRange,numChannels);


% plot fisher scores
multitaperTitle = ['Features discriminancy map based on FS: Multitaper'];
featureDiscrimMultitaper = figure(99);
helperFunctions.plotFisherScores(multitaperParam.frequencyRange,multitaper.fisherScores,multitaperTitle,{chanlocs16.labels})

% perform and plot feature selection for both decoder
multitaper.classError = helperFunctions.featureSelection(multitaper.featMat_allTrials,multitaper.fisherInd,multitaper.trueLabels, classifierParam);
featureSelectionMultitaper = figure(97);
helperFunctions.plotFeatureSelection(multitaper.classError,'Class error for diff no. features - using multitaper')


if doPwelch == 1
    pwelch.featMat = helperFunctions.makeFeatMat(pwelch.pxx);
    pwelch.featMat_allTrials = reshape(pwelch.featMat,[size(pwelch.featMat,1),size(pwelch.featMat,2)*size(pwelch.featMat,3)]);
    pwelch.featMat_allTrials = pwelch.featMat_allTrials';
    pwelch.trueLabels = helperFunctions.makeLabels(stopParam.window,pwelchParam,frameShift,numTrials);
    [pwelch.fisherInd, pwelch.fisherPower] = helperFunctions.rankfeat(pwelch.featMat_allTrials,pwelch.trueLabels, 'fisher');
    pwelch.fisherScores = helperFunctions.projectFeatScores(pwelch.featMat_allTrials,...
        pwelch.fisherInd,pwelch.fisherPower,pwelchParam.frequencyRange,numChannels);
    pwelchTitle = ['Features discriminancy map based on FS: pWelch'];
    featureDiscrimPwelch = figure(98);
    helperFunctions.plotFisherScores(pwelchParam.frequencyRange,pwelch.fisherScores,pwelchTitle,{chanlocs16.labels})
    pwelch.classError = helperFunctions.featureSelection(pwelch.featMat_allTrials,pwelch.fisherInd,pwelch.trueLabels,classifierParam);
    featureSelectionPwelch = figure(96);
    helperFunctions.plotFeatureSelection(pwelch.classError,'Class error for diff no. features - using pwelch')
    
end


%% pseudo online classification (do also for pwelch)


numFeat = 5; % AUTOMATE THIS DECISION

% definable variables
classifierParam.numFeat = numFeat;

% extract pseudoonline epochs & concatenate
[epochPseudoOnline,~] = helperFunctions.epochSessions(sessions, stopParam.Id, pseudoOnlineWindow);
[concatenatedPseudoOnline,~] = helperFunctions.concatSessions(epochPseudoOnline);

% calculate psd - estimates
[pseudoOnlinePxxMultitaper,pseudoOnline_timerMultitaper] ...
    = helperFunctions.calculatePSD(concatenatedPseudoOnline,'multitaper',multitaperParam,frameShift,samplingRate);
% build feature matrix
pseudoOnlineFeatMat = helperFunctions.makeFeatMat(pseudoOnlinePxxMultitaper);
pseudoOnlineFeatMatAllTrials = reshape(pseudoOnlineFeatMat,[size(pseudoOnlineFeatMat,1),size(pseudoOnlineFeatMat,2)*size(pseudoOnlineFeatMat,3)]);
pseudoOnlineFeatMatAllTrials = pseudoOnlineFeatMatAllTrials';

% create a true label vector for the pseudo online
pseudoOnlineTrueLabels = zeros(1,(-pseudoOnlineWindow(1)-multitaperParam.windowSize)*frameShift);
pseudoOnlineTrueLabels = [pseudoOnlineTrueLabels,ones(1,pseudoOnlineWindow(2)*frameShift)];

% perform cross-validation
[class_error_training,pseudoOnlineClassLabels,pseudoOnlineScore] =...
    helperFunctions.pseudoOnlineCrossValidation(multitaper,...
    pseudoOnlineFeatMatAllTrials, classifierParam,pseudoOnlineTrueLabels);

% plot the pseudo online classification

figure(idxFigure)
helperFunctions.plotPseudoOnlineClassification(pseudoOnlineScore,pseudoOnlineWindow,multitaperWindowSize);


%% saving figures

if saveFigures == 1
    
    % figure path
    figPath = strcat('../figures/',testPerson);
    
    % generate figure names
    fDMtName = strcat('classifierType_',classifierType,'_fdm_multitaper_nTaper_ ',num2str(numberOfTappers),'_windSize_',strrep(num2str(multitaperParam.windowSize),'.',','));
    fSMtName = strcat('classifierType_',classifierType,'_fs_multitaper_nTapper_ _ ',num2str(numberOfTappers),'_windSize_',strrep(num2str(multitaperParam.windowSize),'.',','));
    
    saveas(featureDiscrimMultitaper,fullfile(figPath,fDMtName),'fig')
    saveas(featureDiscrimMultitaper,fullfile(figPath,fDMtName),'pdf')
    saveas(featureDiscrimMultitaper,fullfile(figPath,fDMtName),'png')
    saveas(featureSelectionMultitaper,fullfile(figPath,fSMtName),'fig')
    saveas(featureSelectionMultitaper,fullfile(figPath,fSMtName),'pdf')
    saveas(featureSelectionMultitaper,fullfile(figPath,fSMtName),'png')
    
    
    if doPwelch ==1
        fDPwName = strcat('classifierType_',classifierType,'_fdm_pwelch_windSize_',strrep(num2str(pwelchParam.windowSize),'.',','));
        fSPwName = strcat('classifierType_',classifierType,'_fs_pwelch_windSize_',strrep(num2str(pwelchParam.windowSize),'.',','));
        saveas(featureDiscrimPwelch,fullfile(figPath,fDPwName),'fig')
        saveas(featureDiscrimPwelch,fullfile(figPath,fDPwName),'pdf')
        saveas(featureDiscrimPwelch,fullfile(figPath,fDPwName),'png')
        saveas(featureSelectionPwelch,fullfile(figPath,fSPwName),'fig')
        saveas(featureSelectionPwelch,fullfile(figPath,fSPwName),'pdf')
        saveas(featureSelectionPwelch,fullfile(figPath,fSPwName),'png')
        
    end
    
end

clear featureSelectionMultitaper featureDiscrimMultitaper
if doPwelch ==1  
    clear featureDiscrimPwelch featureSelectionPwelch
end
% close all
%% saving variables

if saveVariables == 1
    
    dataPath = strcat('../data/',testPerson);
    currentFilename = strcat('testPerson_',testPerson,'_mtWindowSize_',num2str(multitaperParam.windowSize),...
        '_nTapers_',num2str(numberOfTappers),'_classifier_type_',classifierType,'.mat');
    save(fullfile(dataPath,currentFilename));
end
