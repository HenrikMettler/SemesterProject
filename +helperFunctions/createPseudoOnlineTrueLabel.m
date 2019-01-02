function pseudoOnlineTrueLabel = createPseudoOnlineTrueLabel(windowParam,psdParam,featMat3DPseudoOnline)
pseudoOnlineTrueLabelPerTrial = zeros(1,(-windowParam.pseudoOnlineWindow(1)-psdParam.windowSize)*16);
pseudoOnlineTrueLabelPerTrial = [pseudoOnlineTrueLabelPerTrial,ones(1,windowParam.pseudoOnlineWindow(2)*16)];
pseudoOnlineTrueLabel = [];
for idxTrial = 1:size(featMat3DPseudoOnline,1)
    pseudoOnlineTrueLabel = [pseudoOnlineTrueLabel,pseudoOnlineTrueLabelPerTrial];
end
pseudoOnlineTrueLabel = pseudoOnlineTrueLabel';
end

