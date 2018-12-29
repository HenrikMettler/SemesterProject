function [concatenatedDataZeros,concatenatedDataOnes] = preprocessData(currentFilename,chanlocs16,windowParam)
% PREPROCESSING DATA - performs data preprocessing from .gdf files
%   for each current files, a session is created and stored in an array
%   subsequently spatial filtering (harded-coded with 'CAR' is performed
%   epochs are extracted, and data from the different runs in concatenated
%   if two outputs arguments are defined, data is split into two files
%   (useful for calculating psd spectrum for two different classes)

% create a sessions array
sessions = helperFunctions.createSessions(currentFilename,chanlocs16);

% spatial filtering
for idxSession = 1:size(sessions,2)
    sessions{idxSession}.DATA = helperFunctions.spatFilter(sessions{idxSession}.DATA,'CAR',16);
end

% create epochs 
[epoch] = helperFunctions.epochSessions(sessions, windowParam.Id, windowParam.window);

% concatenate data from diff session for every epoch
[concatenatedData] = helperFunctions.concatSessions(epoch);

% split data into two segments
if nargout == 2
    concatenatedDataZeros = concatenatedData(:,:,1:-windowParam.window(1)*512);
    concatenatedDataOnes = concatenatedData(:,:,-windowParam.window(1)*512+1:end);
end

end

