function [concatenatedData] = concatSessions(epoch)
    concatenatedData = epoch{1}.DATA;
    for idxSession = 2:size(epoch,2)
        concatenatedData = [concatenatedData;epoch{idxSession}.DATA];
    end
end

