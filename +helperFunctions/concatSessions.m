function [concatenatedMotorImagery,concatenatedStop] = concatSessions(epochMotorImagery,epochStop)
    concatenatedMotorImagery = epochMotorImagery{1}.DATA;
    if nargin == 2
        concatenatedStop = epochStop{1}.DATA;
    else
        concatenatedStop = 0;
    end
    
    for idxSession = 2:size(epochMotorImagery,2)
        concatenatedMotorImagery = [concatenatedMotorImagery;epochMotorImagery{idxSession}.DATA];
        if nargin == 2
            concatenatedStop = [concatenatedStop;epochStop{idxSession}.DATA];
        end
    end
end

