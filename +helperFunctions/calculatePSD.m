function [pxx,timer] = calculatePSD(data,method,methodParam,frameShift,samplingRate)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here
%   InputArguments:
%   - data: 3D - Matrix MxNxR: M - number of Trials, 
%                                   N - number of Channels
%                                   R - epoch duration (in sampling rate - 512 -> 1s if samplingRate = 512
%   - windowSize: Scalar: duration of window for spectrum calculation 
%   - samplingRate: Scalar: default 512
%   - frameShift: Scalar: default 16

%% Input validation - Todo methodParams

if nargin == 3
    frameShift = 32; % 32~62.5ms if samplingRate = 512
    samplingRate = 512;
elseif nargin == 4
    samplingRate = 512;
end         

if ndims(data) ~= 3
    error('dataEpoch needs to be 3 dim matrix - nTrials x nChannels x epochDur(in samplingRate')
end

% if windowSize * samplingRate > size(dataEpoch,3)
%     error('Window size is too large - choose it in seconds')
% end


%% set parameters for pxx calculation

windowSize = methodParam.windowSize;
frequencyRange = methodParam.frequencyRange;
numTrials = size(data,1);
numChannels = size(data,2);
numSamples = size(data,3);
numFrequencies = size(frequencyRange,2);
numWindows = ((numSamples-1)/samplingRate - windowSize) * samplingRate/frameShift;
pxx = zeros(numTrials,numWindows,numFrequencies,numChannels);
timer = zeros(numTrials,numWindows);

%% Calculate pxx

for idxTrial = 1:numTrials
    for idxWindow = 1:numWindows
        currentStartIndex = 1+(idxWindow-1)*frameShift; % start index for current window
        currentStopIndex = samplingRate*windowSize + currentStartIndex - 1; % stop index for current window
        currentStopIndex = min(currentStopIndex,numSamples); % avoid end of data frame issues
        currentDataIndices = (currentStartIndex:currentStopIndex); % indices corresp to proper window
        currentData = squeeze(data(idxTrial,:,currentDataIndices)); % squeeze into 2-dim matrix
        
        switch method
            case 'multitaper'
                tic
                [pxx(idxTrial,idxWindow,:,:),~] = pmtm(currentData',methodParam.numberOfTappers,frequencyRange,samplingRate);
                timer(idxTrial,idxWindow) = toc;
                
            case 'pWelch'
                tic
                [pxx(idxTrial,idxWindow,:,:),~] = pwelch(currentData',methodParam.psdWindow,methodParam.psdNOverlap,frequencyRange,samplingRate);
                timer(idxTrial,idxWindow) = toc;
            otherwise
                errror('Method not available, select either multitaper or pWelch')
        end
        
    end
    
end


end

