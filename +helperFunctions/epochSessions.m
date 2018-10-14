function [epochMotorImagery,epochStop] = epochSessions(sessions, motorImageryId, motorImageryWindow,stopId, stopWindow)
    for idxSession = 1:size(sessions,2)
        [epochMotorImagery{idxSession}] = helperFunctions.epoching(sessions{idxSession}, motorImageryId, motorImageryWindow);
        [epochStop{idxSession}] = helperFunctions.epoching(sessions{idxSession}, stopId, stopWindow);
    end
end

