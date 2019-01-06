% Implement random forest classification

%% loading data
addpath(genpath('../rsc')) % path to data and common functions
load('channel_location_16_10-20_mi.mat') % struct containing info about the eeg channels
load('laplacian_16_10-20_mi.mat') % data matrix for laplacian filtering
dataPath = '../rsc/DataFiles/runs_ak3';
files = dir(fullfile(dataPath,'*.gdf'));
currentFilename = {files.name};

%% set parameters

samplingRate = 512;
numChannels = 16;
numTrials = 120;

% psd estimate params - common for all methods
frameShift = 16; % [Herz] -> freq for psd windows

% multitaper parameters - in one struct
multitaperParam.windowSize = 0.5;
multitaperParam.numberOfTappers = 4;
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
classifierParam.type = 'Random Forest';
classifierParam.maxFeat = 30;
classifierParam.numFolds = 10;

%% %% preprocess data

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

multitaper.pxx = cat(2,multitaperZero_pxx,multitaperOne_pxx);
pwelch.pxx = cat(2,pwelchZero_pxx,pwelchOne_pxx);

%% prepare data for decoder

% prepare the data
multitaper.featMat = helperFunctions.makeFeatMat(multitaper.pxx);
% concatenate all data into one array
multitaper.featMat_allTrials = reshape(multitaper.featMat,[size(multitaper.featMat,1),size(multitaper.featMat,2)*size(multitaper.featMat,3)]);
multitaper.featMat_allTrials = multitaper.featMat_allTrials';

pwelch.featMat = helperFunctions.makeFeatMat(pwelch.pxx);
pwelch.featMat_allTrials = reshape(pwelch.featMat,[size(pwelch.featMat,1),size(pwelch.featMat,2)*size(pwelch.featMat,3)]);
pwelch.featMat_allTrials = pwelch.featMat_allTrials';


% create two ground truth for the labels (can be diff, if windowsSize not
% identical)
multitaper.trueLabels = helperFunctions.makeLabels(stopParam.window,multitaperParam,frameShift,numTrials);
pwelch.trueLabels = helperFunctions.makeLabels(stopParam.window,pwelchParam,frameShift,numTrials);

%% RandomForest Classification

% Mdl = TreeBagger(NumTrees,Tbl,Y)  -> syntax specs
multitaperRFModel = TreeBagger(1000,multitaper.featMat_allTrials,multitaper.trueLabels);
[dummyLabels,score] = predict(multitaperRFModel,multitaper.featMat_allTrials);
dummyLabels = cell2mat(dummyLabels);
dummyLabels = str2num(dummyLabels);
dummyClassError = helperFunctions.classerror(multitaper.trueLabels,dummyLabels); 