%% add paths & load general data
addpath(genpath('../rsc')) % path to data and common functions

load('channel_location_16_10-20_mi.mat') % struct containing info about the eeg channels
load('laplacian_16_10-20_mi.mat') % data matrix for laplacian filtering

idxFigure = 1;
%%
switch testPerson
    case 'ak2'
        dataPath = '../rsc/DataFiles/ak2';
    case 'ak3'
        dataPath = '../rsc/DataFiles/ak3';
    case 'ak4'
        dataPath = '../rsc/DataFiles/ak4';    
    case 'ak5'
        dataPath = '../rsc/DataFiles/ak5';    
    case 'ak6'
        dataPath = '../rsc/DataFiles/ak6';    
    case 'ak7'
        dataPath = '../rsc/DataFiles/ak7';    
    case 'ak8'
        dataPath = '../rsc/DataFiles/ak8';    
    case 'ak9'
        dataPath = '../rsc/DataFiles/ak9';    
    case 'al1'
        dataPath = '../rsc/DataFiles/al1';
    otherwise
        error('This subject is not available');
end

files = dir(fullfile(dataPath,'*.gdf'));
currentFilename = {files.name};
