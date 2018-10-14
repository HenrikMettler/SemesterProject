function [concatenatedMotorImagery,concatenatedStop] = concatSessions(epochMotorImagery,epochStop)
    concatenatedMotorImagery = epochMotorImagery{1}.DATA;
    concatenatedStop = epochStop{1}.DATA;

    for idxSession = 2:size(epochMotorImagery,2)
        concatenatedMotorImagery = [concatenatedMotorImagery;epochMotorImagery{idxSession}.DATA];
        concatenatedStop = [concatenatedStop;epochStop{idxSession}.DATA];
    end
end

