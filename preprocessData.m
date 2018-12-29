function preprocessedData = preprocessData(currentFilename,chanlocs16)
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here

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


end

