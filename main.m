%% MAIN SCRIPT

% used for running various configurations in one run

%% add paths & load general data
addpath(genpath('../rsc')) % path to data and common functions

load('channel_location_16_10-20_mi.mat') % struct containing info about the eeg channels
load('laplacian_16_10-20_mi.mat') % data matrix for laplacian filtering

%% DEFINABLE VARIABLES

testPersons = {'ak2','ak3'}; % add more here...
multitaperWindowSizes = [1,0.5,0.25];
numberOfTappersArray = 3:8;
classifierType = 'diaglinear'; % options (to be defined) 
saveFigures = 1; % boolean
saveVariables = 1; % boolean


% create a for loop for each variable which has more than one option

for idxTestPerson = 1:size(testPersons,2)
    testPerson = testPersons{idxTestPerson};
    for idxMtWs = 1:size(multitaperWindowSizes,2)
        multitaperWindowSize = multitaperWindowSizes(idxMtWs);
        for idxNTap = 1:size(numberOfTappersArray,2)
            numberOfTappers = numberOfTappersArray(idxNTap);
            
            % run the processing and decoding script here
            processAndDecode
        end
    end
end


