function [Epoch] = epoching(session,eventID,time_window)

    %finds the event associated with the given ID
    pos = session.EVENT.POS(session.EVENT.TYP == eventID);
    
    %find tsarts and tstops given the time window
    %for example, time_window could be [-3,1], meaning bewteen 3s before 
    %event and 1s after.
    time_window = time_window*session.SR;
    tstart = time_window(1) + pos;
    tstop = time_window(2) + pos;
    
    Dur = unique(tstop-tstart) + 1;
    NumTrials = length(tstart);
    NumCh = 16;
    
    Data = zeros(NumTrials, NumCh, Dur);
    T = zeros(NumTrials,Dur);
    
    for idxTrial = 1:NumTrials
        Data(idxTrial,:,:) = session.DATA(1:NumCh,tstart(idxTrial):tstop(idxTrial));
        T(idxTrial,:) = tstart(idxTrial):1:tstop(idxTrial);
    end
    T = T/session.SR;
    
    Epoch.DATA = Data;
    Epoch.ChINFO = session.ChINFO;
    Epoch.EVENT = pos/session.SR;
    Epoch.TIME = T;
end

