function [pxx,timer] = calculatePSD(dataEpoch,method,methodParam,frameShift,samplingRate)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here
%   InputArguments:
%   - dataEpoch: 3D - Matrix MxNxR: M - number of Trials, 
%                                   N - number of Channels
%                                   R - epoch duration (in sampling rate - 512 -> 1s if samplingRate = 512
%   - windowSize: Scalar: duration of window for spectrum calculation 
%   - samplingRate: Scalar: default 512
%   - frameShift: Scalar: default 16

%% Input validation - Todo methodParams

if nargin == 4
    frameShift = 16;
    samplingRate = 512;
elseif nargin == 5
    samplingRate = 512;
end         

if ndims(dataEpoch) ~= 3
    error('dataEpoch needs to be 3 dim matrix - nTrials x nChannels x epochDur(in samplingRate')
end

% if windowSize * samplingRate > size(dataEpoch,3)
%     error('Window size is too large - choose it in seconds')
% end


%% set parameters for pxx calculation

windowSize = methodParam.windowSize;
frequencyRange = methodParam.frequencyRange;
numTrials = size(dataEpoch,1);
numChannels = size(dataEpoch,2);
numFrequencies = size(frequencyRange,2);
numWindows = (floor(size(dataEpoch,3)/samplingRate)-windowSize)*frameShift;
pxx = zeros(numTrials,numWindows,numFrequencies,numChannels);
timer = zeros(numTrials,numWindows);

%% Calculate pxx

for idxTrial = 1:numTrials
    for idxWindow = 1:numWindows
        currentStartIndex = 1+(idxWindow-1)*windowSize*samplingRate/frameShift; % start index for current window
        currentStopIndex = samplingRate*windowSize + currentStartIndex - 1; % stop index for current window
        currentStopIndex = min(currentStopIndex,size(dataEpoch,3)); % avoid end of data frame issues
        currentDataIndices = (currentStartIndex:currentStopIndex); % indices corresp to proper window
        currentData = squeeze(dataEpoch(idxTrial,:,currentDataIndices)); % squeeze into 2-dim matrix
        
        switch method
            case 'multitaper'
                tic
                [pxx(idxTrial,idxWindow,:,:),~] = pmtm(currentData',methodParam.numberOfTappers,frequencyRange,samplingRate);
                timer(idxTrial,idxWindow) = toc;
                
            case 'pwelch'
                tic
                [pxx(idxTrial,idxWindow,:,:),~] = pwelch(currentData',methodParam.psdWindow,methodParam.psdNOverlap,frequencyRange,samplingRate);
                timer(idxTrial,idxWindow) = toc;
            otherwise
                errror('Method not available, select either multitaper or pwelch')
        end
        
    end
    
end


end

