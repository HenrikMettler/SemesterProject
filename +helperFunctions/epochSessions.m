function [epoch] = epochSessions(sessions,epochId, epochWindow)
    for idxSession = 1:size(sessions,2)
        [epoch{idxSession}] = helperFunctions.epoching(sessions{idxSession}, epochId, epochWindow);
    end
end

