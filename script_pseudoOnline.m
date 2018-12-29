% definable variables
testPerson = 'ak3'; % current options: ak2, ak3
method = 'multitaper'; % options: pwelch, multitaper
pseudoOnlineWindow = [-4,3]; % window for pseudoonline class: note class starts at t(1) + windowSize
numfeat = 5;

pseudoOnlineID = 555; % same as MI-stop! (shouldn't be changed)
pseudoOnlineClassifierParameters.numFeat = numfeat;
pseudoOnlineClassifierParameters.numFolds = 10;


%% add data path & initialize files

addpath(genpath('../rsc')); % path to data and common functions
addpath(genpath('../data')); % path to data and common functions

load('channel_location_16_10-20_mi.mat') % struct containing info about the eeg channels

fileList = dir(['../data/',testPerson,'/*.mat']);

%% perform pseudo online cross-validation (for all files)

for idxFile = 48 %1:size(fileList,1)
    load(fullfile(['../data/',testPerson],fileList(idxFile).name));
    pseudoOnlineClassifierParameters.type = classifierParam.type;
    
    % temporary label rebuilding
    multitaper.trueLabels = reshape(multitaper.trueLabels,[size(multitaper.featMat,2),size(multitaper.featMat,3)]);
    multitaper.trueLabels = multitaper.trueLabels(:,1);
    
    % extract pseudoonline epochs & concatenate
    [epochPseudoOnline,~] = helperFunctions.epochSessions(sessions, pseudoOnlineID, pseudoOnlineWindow);
    [concatenatedPseudoOnline,~] = helperFunctions.concatSessions(epochPseudoOnline);
    % calculate psd - estimates
    [pseudoOnline_pxx,pseudoOnline_timer] = helperFunctions.calculatePSD(concatenatedPseudoOnline,method,multitaperParam,frameShift,samplingRate);
    % build feature matrix
    pseudoOnlineFeatMat = helperFunctions.makeFeatMat(pseudoOnline_pxx);
    
    % normalize pseudoonline features
    
    % pseudoOnlineFeatMat = zscore(pseudoOnlineFeatMat,0,2);
    
    % create a true label vector for the pseudo online
    pseudoOnlineTrueLabels = zeros(1,(-pseudoOnlineWindow(1)-multitaperParam.windowSize)*frameShift);
    pseudoOnlineTrueLabels = [pseudoOnlineTrueLabels,ones(1,pseudoOnlineWindow(2)*frameShift)];
    
    % perform a cross-validation
    switch method
        case 'multitaper'         
            [class_error_training{idxFile},pseudoOnlineClassLabels{idxFile},pseudoOnlineScore{idxFile}] =...
                helperFunctions.pseudoOnlineCrossValidation(multitaper,...
                pseudoOnlineFeatMat, pseudoOnlineClassifierParameters,pseudoOnlineTrueLabels);
        case 'pwelch'
            [pwelchError,pwelchLabels},pwelchScore] =...
                helperFunctions.pseudoOnlineCrossValidation(pwelch,...
                pseudoOnlineFeatMat, pseudoOnlineClassifierParameters,pseudoOnlineTrueLabels);
        otherwise
            error('Method non existant');
    end
    
    %% plot the pseudo online classification 

    figure(idxFile)
    helperFunctions.plotPseudoOnlineClassification(pseudoOnlineScore{idxFile},pseudoOnlineWindow,multitaperWindowSize);

    
end


