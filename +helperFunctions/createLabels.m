function  labels = createLabels(session,time_window_init, time_window_term)
% CREATE A LABEL VECTOR
% finds position with the label for MI-init ('400') and labels the time
% in the time window time_window_init with 1; 
% finds position with the label for MI-term ('555') and labels the time
% in the time window time_window_init with 2; 

% initialize an empty label vector
labels = zeros(size(session.DATA,2),1);

% finds the positions of MI - initiation / MI - termination
pos_mi_init = session.EVENT.POS(session.EVENT.TYP == 400);
pos_mi_term = session.EVENT.POS(session.EVENT.TYP == 555);

% label time window after MI-init with 1
for idxPos=1:size(pos_mi_init,1)
    labels(pos_mi_init(idxPos):pos_mi_init+time_window_init*session.SR) = 1;
end

for idxPos=1:size(pos_mi_term,1)
    labels(pos_mi_term(idxPos):pos_mi_term+time_window_term*session.SR) = 2;
end
end