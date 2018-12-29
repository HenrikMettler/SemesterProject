%% MAIN SCRIPT

% used for running various configurations in one run

mainMode = 1;


%% add paths & load general data
addpath(genpath('../rsc')) % path to data and common functions

load('channel_location_16_10-20_mi.mat') % struct containing info about the eeg channels
load('laplacian_16_10-20_mi.mat') % data matrix for laplacian filtering
    

%% DEFINABLE VARIABLES

testPersons = {'ak2','ak3','ak4','ak5','ak6','ak7','ak8','ak9','al1'}; % are of all test persons that should be used

psdModes = {'multitaper','pWelch'}; % select which psd estimators are to be used - available multitaper, pwelch
multitaperWindowSizes = [1,0.5,0.25]; % multitaper window sizes - can be empty if multitaper estimator not used
numberOfTappersArray = [3,5,10,50]; % different number of tappers used - can be empty if multitaper estimator not used

classifierTypes = {'diaglinear','linear','randomForest'}; % available: diaglinear, linear, randomForest

% window parameters
windowParam.Id = 555; % stop: '555', mi: '400'
windowParam.window = [-2,2];

pseudoOnlineWindow = [-4,6]; % window for pseudoonline class: note class starts at t(1) + windowSize

saveFigures = 1; % boolean
saveVariables = 1; % boolean
verbose = 1; % boolean for print statements

saveFlag = [saveFigures,saveVariables];

%% run for different configurations


for idxTestPerson = 1:size(testPersons,2)
    testPerson = testPersons{idxTestPerson};
    % select corresponding data files
    dataPath = ['../rsc/DataFiles/',testPerson];
    files = dir(fullfile(dataPath,'*.gdf'));
    currentFilename = {files.name};
    
    % preprocess data (independent of parameter configurations
    [concatenatedDataZeros,concatenatedDataOnes] = preprocessData(currentFilename,chanlocs16,windowParam);
    
    for idxClassifierType = 1:size(classifierTypes,2)
        classifierType = classifierTypes{1,idxClassifierType};
        for idxPSDM = 1:size(psdModes,2)
            psdMode = psdModes{idxPSDM};
            switch psdMode
                case 'multitaper'
                    for idxMtWs = 1:size(multitaperWindowSizes,2)
                        psdParam.windowSize = multitaperWindowSizes(idxMtWs);
                        psdParam.frequencyRange = 4:1/psdParam.windowSize:40;

                        for idxNTap = 1:size(numberOfTappersArray,2)
                            psdParam.numberOfTappers = numberOfTappersArray(idxNTap);
                            % call the processing and decoding function
                            processAndDecode(concatenatedDataZeros,concatenatedDataOnes,classifierType,psdMode,psdParam,saveFlag,verbose)
                        end
                    end
                case 'pWelch'
                    % pwelch parameters - in one struct
                    psdParam.psdWindow = 0.5;
                    psdParam.psdNOverlap = 0.25;
                    psdParam.frequencyRange = 4:2:40;
                    
                    % call the processing and decoding function
                    processAndDecode(classifierType,psdMode,psdParam,saveFlag,verbose)
            end
            
            
        end
    end
end


