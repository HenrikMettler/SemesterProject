%% MAIN SCRIPT

% used for running various configurations in one run

%% add paths & load general data
addpath(genpath('../rsc')) % path to data and common functions

load('channel_location_16_10-20_mi.mat') % struct containing info about the eeg channels
load('laplacian_16_10-20_mi.mat') % data matrix for laplacian filtering

idxFigure = 1;

%% DEFINABLE VARIABLES

testPersons = {'ak3'};%{'ak2','ak3'}; % add more here...
multitaperWindowSizes = [1,0.5,0.25];%[1,0.75,0.5,0.25];
numberOfTappersArray = 4;
classifierTypes = {'diaglinear'};%,'linear'}; % options (to be extended to random forest, svm) 
saveFigures = 1; % boolean
saveVariables = 1; % boolean
doPwelch = 1; % boolean

% create a for loop for each variable which has more than one option
for idxClassifierType = 1:size(classifierTypes,2)
    classifierType = classifierTypes{1,idxClassifierType};
    for idxTestPerson = 1:size(testPersons,2)
        testPerson = testPersons{idxTestPerson};
        for idxMtWs = 1:size(multitaperWindowSizes,2)
            multitaperWindowSize = multitaperWindowSizes(idxMtWs);
            for idxNTap = 1:size(numberOfTappersArray,2)
                numberOfTappers = numberOfTappersArray(idxNTap);                
                % check whether its necessary to do pwelch
                if idxMtWs > 1 || idxNTap > 1
                    doPwelch = 0;
                end
                % run the processing and decoding script here
                processAndDecode
                
                idxFigure = idxFigure + 1;
            end
        end
        doPwelch = 1;
    end
end


