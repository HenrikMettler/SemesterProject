% definable variables
numFeat = 5; % dummy example -> implement decision 
testPerson = 'ak3'; % current options: ak2, ak3
method = 'multitaper'; % options: pwelch, multitaper
pseudoOnlineWindow = [-4,3]; % window for pseudoonline class: note class starts at t(1) + windowSize


pseudoOnlineID = 555; % same as MI-stop! (shouldn't be changed)
pseudoOnlineClassifierParameters.numFeat = numFeat;
pseudoOnlineClassifierParameters.numFolds = 10;


%% add data path 

addpath(genpath('../rsc')); % path to data and common functions
addpath(genpath('../data')); % path to data and common functions

load('channel_location_16_10-20_mi.mat') % struct containing info about the eeg channels

files = dir(['../data/',testPerson,'/*.mat']);

for idxFile = 1%:size(files,1)
    load(fullfile(['../data/',testPerson],files(idxFile).name));
    onlineClassifierParameters.type = classifierParam.type;

    % extract pseudoonline epochs & concatenate
    [epochPseudoOnline,~] = helperFunctions.epochSessions(sessions, pseudoOnlineID, pseudoOnlineWindow);
    [concatenatedPseudoOnline,~] = helperFunctions.concatSessions(epochPseudoOnline);
    % calculate psd - estimates
    [pseudoOnline_pxx,pseudoOnline_timer] = helperFunctions.calculatePSD(concatenatedPseudoOnline,'multitaper',multitaperParam,frameShift,samplingRate);
    % build feature matrix
    pseudoOnlineFeatMat = helperFunctions.makeFeatMat(pseudoOnline_pxx);
    
    
    % perform a cross-validation
    switch method
        case 'multitaper'         
            helperFunctions.pseudoOnlineCrossValidation(multitaper.featMat,...
                pseudoOnlineFeatMat, pseudoOnlineClassifierParameters)
        case 'pwelch'
            helperFunctions.pseudoOnlineCrossValidation(pwelch.featMat_allTrials,...
                pseudoOnline_featMatAllTrials, pseudoOnlineClassifierParameters)
        otherwise
            error('Method non existant');
    end
    
    
    
end




