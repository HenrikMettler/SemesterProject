%% INITIAL SCRIPT FOR IMPLEMENTING MULTITAPER

a = 1;

% add paths & load general data
addpath(genpath('../rsc')) % path to data and common functions

load('channel_location_16_10-20_mi.mat') % struct containing info about the eeg channels
load('laplacian_16_10-20_mi.mat') % data matrix for laplacian filtering

%% DEFINABLE VARIABLES

testPerson = 'ak3'; % options: 'ak2','ak3'
signalProcessingType = 'multitaper'; % options: 'fastPWelch', 'multitaper'
classifierType = 'diaglinear'; % options (to be defined) 

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
filename = {files.name};


%% set parameters

samplingRate = 512;
numChannels = 16;
numTrials = 120;

% multitaper parameters
windowSize = 1; % in seconds
frameShift = 16; % [Herz] -> freq for psd windows
numberOfTappers = 6; % so far this is not actually used...
nw = 4; % is this actually the number of tappers -> go check function!
frequency_range = [4:2:40]; % frequency range of the signal we are interested in 

% epoching parameters
motorImageryId = 400; 
stopId = 555;
motorImageryWindow = [-2,2];
miStopWindow = [-2,2];

% spatial filtering parameters 
order = 4;
spat_type = 'CAR';

% fast PWelch parameters 
psdWindow = 0.5*samplingRate;
psdNOverlap = 0.25*samplingRate;




movingAverageLength = 1;
windowLength = 0.5;
psdWindowShift = 0.25;                  
externalWindowShift = 0.0625;              
params_spectrogram.selchans   = 1:16;     
spectrogramFrequencies = 4:2:40;
SF = 16;

% classifier parameters 
time_window_init = 1;
time_window_term = 1;
type = classifierType;
maxFeat = 30;
stepFeat = 1;
fold = 10;


%% preprocess data

% create a sessions array
sessions = helperFunctions.createSessions(filename,chanlocs16);

% spatial filtering
for idxSession = 1:size(sessions,2)
    sessions{idxSession}.DATA = helperFunctions.spatFilter(sessions{idxSession}.DATA, spat_type, lap, numChannels);
end

% segment data into windows of window size
for idxSession = 1: size(sessions,2)
    numWindows = ceil(size(sessions{idxSession}.DATA,2)/(windowSize*samplingRate/frameShift));
    
    for idxWindow = 1:numWindows
        startWindow = (idxWindow-1)*samplingRate/frameShift*windowSize+1;
        stopWindow = idxWindow*samplingRate/frameShift*windowSize;
        sessions{idxSession}.DATA_windowed{idxWindow} = sessions{idxSession}.DATA(:,startWindow:stopWindow);
    end
end

% define ground-truth vectors for decoder (NO LONGER NEEDED 1410)
for idxSession=1:size(sessions,2)
    sessions{idxSession}.LABELS = helperFunctions.createLabels(sessions{idxSession},time_window_init,time_window_term);
end

% create epochs around MI-Init and MI-Term
[epochMotorImagery,epochStop] = helperFunctions.epochSessions(sessions, motorImageryId, motorImageryWindow,stopId, miStopWindow);

% concatenate data from diff session for every epoch
[concatenatedMotorImagery,concatenatedStop] = helperFunctions.concatSessions(epochMotorImagery,epochStop);


%% implement multitaper

% "[pxx,f] = pmtm(x,nw,f,fs) returns the two-sided multitaper PSD estimates at the frequencies specified in the vector, f.
%  f must contain at least two elements. The frequencies in f are in cycles per unit time. 
%  The sampling frequency, fs, is the number of samples per unit time. If
%  the unit of time is seconds, then f is in cycles/second (Hz)."

% calculate number of windows
numWindows = floor((size(concatenatedStop,3)-windowSize*samplingRate)/(windowSize*samplingRate/frameShift));
% initialize multitaper_pxx cell array(s) for comp.efficency (quicker computation)
multitaper_pxx_stop = zeros(numTrials,numWindows,size(frequency_range,2),numChannels);
% multitaper_pxx_init 
multitaper_timer = zeros(numTrials,numWindows);



for idxTrial = 1:numTrials
        
    for idxWindow = 1:numWindows
        % extract current data
        currentStartIndex = 1+(idxWindow-1)*windowSize*samplingRate/frameShift; % start index for current window
        currentStopIndex = samplingRate*windowSize + currentStartIndex - 1; % stop index for current window
        currentStopIndex = min(currentStopIndex,size(concatenatedStop,3)); % avoid end of data frame issues
        currentDataIndices = (currentStartIndex:currentStopIndex); % indices corresp to proper window
        currentData = squeeze(concatenatedStop(idxTrial,:,currentDataIndices)); % squeeze into 2-dim matrix
        
        % calculate the spectral estimate using multitaper
        tic
        [multitaper_pxx_stop(idxTrial,idxWindow,:,:),~] = pmtm(currentData',nw,frequency_range,samplingRate);
        multitaper_timer(idxTrial,idxWindow) = toc;
        
        % calculate the spectral estimate using pwelch
        tic
        [pwelch_pxx_stop(idxTrial,idxWindow,:,:),~] = pwelch(currentData',psdWindow,psdNOverlap,frequency_range,16);
        pwelch_timer(idxTrial,idxWindow) = toc;
%         
    end
end

%% build the decoder

% prepare the data
multitaper_stop_featMat = helperFunctions.makeFeatMat(multitaper_pxx_stop);
pwelch_stop_featMat = helperFunctions.makeFeatMat(pwelch_pxx_stop);
% concatenate all data into one array (for both)
multitaper_stop_featMat_allTrials = reshape(multitaper_stop_featMat,[size(multitaper_stop_featMat,1),size(multitaper_stop_featMat,2)*size(multitaper_stop_featMat,3)]);
pwelch_stop_featMat_allTrials = reshape(pwelch_stop_featMat,[size(pwelch_stop_featMat,1),size(pwelch_stop_featMat,2)*size(pwelch_stop_featMat,3)]);


% create a ground truth for the labels
zero_labels =  zeros(ceil(frameShift*(abs(miStopWindow(1))-windowSize)),1);
one_labels = ones(floor(frameShift*miStopWindow(2)),1);
labelPerTrial = [zero_labels;one_labels];
trueLabels = [];
for idxTrial = 1:numTrials
    trueLabels = [trueLabels;labelPerTrial];
end

% normalize the features (! needs to be done after doing CV-split!
multitaper_stop_featMat_allTrials = zscore(multitaper_stop_featMat_allTrials');
pwelch_stop_featMat_allTrials = zscore(pwelch_stop_featMat_allTrials');

% rank the features using fisher score
[multitaper_fisherInd, multitaper_fisherPower] = helperFunctions.rankfeat(multitaper_stop_featMat_allTrials,trueLabels, 'fisher');
[pwelch_fisherInd, pwelch_fisherPower] = helperFunctions.rankfeat(pwelch_stop_featMat_allTrials,trueLabels, 'fisher');
