function [epochMotorImagery,epochStop] = epochSessions(sessions, motorImageryId, motorImageryWindow,stopId, stopWindow)
    for idxSession = 1:size(sessions,2)
        [epochMotorImagery{idxSession}] = helperFunctions.epoching(sessions{idxSession}, motorImageryId, motorImageryWindow);
        if nargin == 5
            [epochStop{idxSession}] = helperFunctions.epoching(sessions{idxSession}, stopId, stopWindow);
        end
    end
    if nargin == 3
        epochStop = 0; % ugly hack to abuse the function...
    end
end

