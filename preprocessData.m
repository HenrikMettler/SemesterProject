function data = preprocessData(currentFilename,chanlocs16,windowParam,verbose)
% PREPROCESSING DATA - performs data preprocessing from .gdf files
%   for each current files, a session is created and stored in an array
%   subsequently spatial filtering (harded-coded with 'CAR' is performed
%   epochs are extracted, and data from the different runs in concatenated
%   the data is then stored into a struct, with two fields:
%    -offlineZero: data before MI - termination
%   - offlineOne: data after MI - termination
%   if a pseudoOnline window is defined, data contains a third field 'pseudoOnline' 


if isfield(windowParam,'pseudoOnlineWindow')
    doPseudoOnline = 1;
else 
    doPseudoOnline = 0;
end

if verbose == 1
    disp('*** STARTED DATA PREPROCESSING ***')
end

% create a sessions array
sessions = helperFunctions.createSessions(currentFilename,chanlocs16);

% spatial filtering
for idxSession = 1:size(sessions,2)
    sessions{idxSession}.DATA = helperFunctions.spatFilter(sessions{idxSession}.DATA,'CAR',16);
end

% create epochs 
offlineEpochZero = helperFunctions.epochSessions(sessions, windowParam.Id, [windowParam.offlineWindow(1),0]);
offlineEpochOne = helperFunctions.epochSessions(sessions, windowParam.Id, [0,windowParam.offlineWindow(2)]);

% concatenate data from diff session for every epoch
data.offlineZero = helperFunctions.concatSessions(offlineEpochZero);
data.offlineOne = helperFunctions.concatSessions(offlineEpochOne);

% split offline data in two parts - before MI-term and after
% data.offlineZero = 

if doPseudoOnline == 1
    pseudoOnlineEpoch = helperFunctions.epochSessions(sessions, windowParam.Id, windowParam.pseudoOnlineWindow);
    data.pseudoOnline = helperFunctions.concatSessions(pseudoOnlineEpoch);
end

if verbose == 1
    disp('*** DATE PREPROCESSING FINISHED ***')
end

end

