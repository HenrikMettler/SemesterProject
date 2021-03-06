%% MULTITAPER SIGNAL PROCESSING IMPLEMENTATION

% % add paths & load general data
% addpath(genpath('../rsc')) % path to data and common functions
% 
% load('channel_location_16_10-20_mi.mat') % struct containing info about the eeg channels
% load('laplacian_16_10-20_mi.mat') % data matrix for laplacian filtering
% 
% %% DEFINABLE VARIABLES
% 
% testPerson = 'ak3'; % options: 'ak2','ak3'
% multitaperWindowSize = 1; % "meaningful" options: 1,0.5,0.25
% numberOfTappers = 4; % try 3:8
% classifierType = 'diaglinear'; % options (to be defined) 
% saveFigures = 1; % boolean

%%
switch testPerson
    case 'ak2'
        dataPath = '../rsc/data/runs_ak2';
    case 'ak3'
        dataPath = '../rsc/data/runs_ak3';
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
frequencyRange = [4:2:40]; % frequency range of the signal we are interested in 

% multitaper parameters - in one struct
multitaperParam.windowSize = multitaperWindowSize;
multitaperParam.numberOfTappers = numberOfTappers;
multitaperParam.frequencyRange = frequencyRange;

% pwelch parameters - in one struct
pwelchParam.psdWindow = 0.5*samplingRate;
pwelchParam.psdNOverlap = 0.25*samplingRate;
pwelchParam.frequencyRange = frequencyRange;
pwelchParam.windowSize = 1;

% epoching parameters
miParam.Id = 400; 
miParam.window = [-2,2];
stopParam.Id = 555;
stopParam.window = [-2,2];

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
[pwelchZero_pxx,pwelchZero_timer] = helperFunctions.calculatePSD(concatenatedStopZeros,'pwelch',pwelchParam,frameShift,samplingRate);
[pwelchOne_pxx,pwelchOne_timer] = helperFunctions.calculatePSD(concatenatedStopOnes,'pwelch',pwelchParam,frameShift,samplingRate);

multitaper_pxx = cat(2,multitaperZero_pxx,multitaperOne_pxx);
pwelch_pxx = cat(2,pwelchZero_pxx,pwelchOne_pxx);

%% build the decoder

% prepare the data
multitaper_featMat = helperFunctions.makeFeatMat(multitaper_pxx);
pwelch_featMat = helperFunctions.makeFeatMat(pwelch_pxx);
% concatenate all data into one array (for both)
multitaper_featMat_allTrials = reshape(multitaper_featMat,[size(multitaper_featMat,1),size(multitaper_featMat,2)*size(multitaper_featMat,3)]);
pwelch_featMat_allTrials = reshape(pwelch_featMat,[size(pwelch_featMat,1),size(pwelch_featMat,2)*size(pwelch_featMat,3)]);


% create two ground truth for the labels (can be diff, if windowsSize not
% identical)
multitaperTrueLabels = helperFunctions.makeLabels(stopParam.window,multitaperParam,frameShift,numTrials);
pwelchTrueLabels = helperFunctions.makeLabels(stopParam.window,pwelchParam,frameShift,numTrials);

% normalize the features (! needs to be done after doing CV-split!)
multitaper_featMat_allTrials = zscore(multitaper_featMat_allTrials');
pwelch_featMat_allTrials = zscore(pwelch_featMat_allTrials');

% rank the features (currently fisher method is used)
[multitaper_fisherInd, multitaper_fisherPower] = helperFunctions.rankfeat(multitaper_featMat_allTrials,multitaperTrueLabels, 'fisher');
[pwelch_fisherInd, pwelch_fisherPower] = helperFunctions.rankfeat(pwelch_featMat_allTrials,pwelchTrueLabels, 'fisher');

% project the fisher score onto a 2D image channel x frequency
multitaper_fisherScores = helperFunctions.projectFeatScores(multitaper_featMat_allTrials,...
    multitaper_fisherInd,multitaper_fisherPower,frequencyRange,numChannels);
pwelch_fisherScores = helperFunctions.projectFeatScores(pwelch_featMat_allTrials,...
    pwelch_fisherInd,pwelch_fisherPower,frequencyRange,numChannels);

% plot fisher scores
multitaperTitle = ['Features discriminancy map based on FS: Multitaper'];
pwelchTitle = ['Features discriminancy map based on FS: pWelch'];
featureDiscrimMultitaper = figure(99);
helperFunctions.plotFisherScores(frequencyRange,multitaper_fisherScores,multitaperTitle,{chanlocs16.labels})
featureDiscrimPwelch = figure(98);
helperFunctions.plotFisherScores(frequencyRange,pwelch_fisherScores,pwelchTitle,{chanlocs16.labels})


% perform and plot feature selection for both decoder
multitaperClassError = helperFunctions.featureSelection(multitaper_featMat_allTrials,multitaper_fisherInd,multitaperTrueLabels, classifierParam);
pwelchClassError = helperFunctions.featureSelection(pwelch_featMat_allTrials,pwelch_fisherInd,pwelchTrueLabels,classifierParam);
featureSelectionMultitaper = figure(97);
helperFunctions.plotFeatureSelection(multitaperClassError,'Class error for diff no. features - using multitaper')
featureSelectionPwelch = figure(96);
helperFunctions.plotFeatureSelection(pwelchClassError,'Class error for diff no. features - using pwelch')

%% saving figures

if saveFigures == 1
    
    % figure path
    figPath = strcat('../figures/',testPerson);
    
    % generate figure names
    fDMtName = strcat('feat_disc_map_multitaper_nTaper_ ',num2str(numberOfTappers),'_windSize_',strrep(num2str(multitaperParam.windowSize),'.',','));
    fDPwName = strcat('feat_disc_map_pwelch_windSize_',strrep(num2str(pwelchParam.windowSize),'.',','));
    fSMtName = strcat('feat_select_multitaper_nTapper_ _ ',num2str(numberOfTappers),'_windSize_',strrep(num2str(multitaperParam.windowSize),'.',','));
    fSPwName = strcat('feat_select_pwelch_windSize_',strrep(num2str(pwelchParam.windowSize),'.',','));

    saveas(featureDiscrimMultitaper,fullfile(figPath,fDMtName),'fig')
    saveas(featureDiscrimMultitaper,fullfile(figPath,fDMtName),'pdf')
    saveas(featureDiscrimMultitaper,fullfile(figPath,fDMtName),'png')
    saveas(featureDiscrimPwelch,fullfile(figPath,fDPwName),'fig')
    saveas(featureDiscrimPwelch,fullfile(figPath,fDPwName),'pdf')
    saveas(featureDiscrimPwelch,fullfile(figPath,fDPwName),'png')
    saveas(featureSelectionMultitaper,fullfile(figPath,fSMtName),'fig')
    saveas(featureSelectionMultitaper,fullfile(figPath,fSMtName),'pdf')
    saveas(featureSelectionMultitaper,fullfile(figPath,fSMtName),'png')
    saveas(featureSelectionPwelch,fullfile(figPath,fSPwName),'fig')
    saveas(featureSelectionPwelch,fullfile(figPath,fSPwName),'pdf')
    saveas(featureSelectionPwelch,fullfile(figPath,fSPwName),'png')
   
end

close all
%% saving variables

if saveVariables == 1
    
    % prepare variables
    
    multitaper.featMat = multitaper_featMat;
    multitaper.featMat_allTrials = multitaper_featMat_allTrials;
    multitaper.fisherInd = multitaper_fisherInd
    
    dataPath = strcat('../data/',testPerson);
    currentFilename = strcat('testPerson_',testPerson,'_mtWindowSize_',num2str(multitaperParam.windowSize),...
        '_nTapers_',num2str(numberOfTappers),'_classifier_type',classifierType,'.mat');
    save(fullfile(dataPath,currentFilename),'miParam',);
end
