function [sessions] = createSessions(filename,chanlocs16)
    for idxFile = 1:size(filename,2)
        [s, h] = sload(filename{idxFile}); % s = signal: matrix sample (rows) x channels (columns)
        % h = header, event is the most important field
        s = s(:,1:16);

        %Create structure session
        session_event.TYP = h.EVENT.TYP;
        session_event.POS = h.EVENT.POS;
        session.SR = h.SampleRate;
        session.DATA = s';
        session.ChINFO = chanlocs16;     % chanlocs16.labels: correspond to an electrode
        session.EVENT = session_event;
        sessions{idxFile} = session; % sessions array: containing all session in order of files
    end
end

