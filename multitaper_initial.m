%% INITIAL SCRIPT FOR IMPLEMENTING MULTITAPER

% add paths & load general data
addpath(genpath('../rsc')) % subfolder of helper functions

load('channel_location_16_10-20_mi.mat') % struct containing info about the eeg channels
load('laplacian_16_10-20_mi.mat') % data matrix for laplacian filtering

%% DEFINABLE VARIABLES

testPerson = 'ak3'; % options: 'ak2','ak3','all'
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



% filtering parameters 
order = 4;% must be even --> will be divided by 2
spat_type = 'CAR';

% fast PWelch parameters 
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
    nWindows = ceil(size(sessions{idxSession}.DATA,2)/(windowSize*samplingRate/frameShift));
    
    for idxWindow = 1:nWindows
        startWindow = (idxWindow-1)*samplingRate/frameShift*windowSize+1;
        stopWindow = idxWindow*samplingRate/frameShift*windowSize;
        sessions{idxSession}.DATA_windowed{idxWindow} = sessions{idxSession}.DATA(:,startWindow:stopWindow);
    end
end

% define ground-truth vectors for decoder
for idxSession=1:size(sessions,2)
    sessions{idxSession}.LABELS = helperFunctions.createLabels(sessions{idxSession},time_window_init,time_window_term);
end

%% implement multitaper

% "[pxx,f] = pmtm(x,nw,f,fs) returns the two-sided multitaper PSD estimates at the frequencies specified in the vector, f.
%  f must contain at least two elements. The frequencies in f are in cycles per unit time. 
%  The sampling frequency, fs, is the number of samples per unit time. If
%  the unit of time is seconds, then f is in cycles/second (Hz)."

% initialize multitaper_pxx cell array
multitaper_pxx = c

for idxSession = 1:size(sessions,2)
    % initialize multitaper_pxx{idx_session} for comp.efficency (and
    % quicker computation
    
    nWindows = ceil(size(sessions{idxSession}.DATA,2)/(windowSize*samplingRate/frameShift));
    for idxWindow = 1:nWindows
        tic
        currentData = sessions{idxSession}.DATA_windowed{idxWindow};
        [mutlitaper_pxx{idxSession}(idxWindow,:,:),~] = pmtm(currentData',nw,frequency_range,samplingRate);
        multitaper_timer{idxSession}(idxWindow) = toc;
    end
end

temp_pxx = squeeze(mutlitaper_pxx{1}(413,:,:));


