function plotPseudoOnlineClassification(pseudoOnlineScore,pseudoOnlineWindow,psdParam)

startingPoint = pseudoOnlineWindow(1) + psdParam.windowSize;
timeVector = startingPoint:1/16:pseudoOnlineWindow(2);
timeVector = timeVector(2:end);

currentScore = []; 
for idxFold = 1:size(pseudoOnlineScore,2)
    currentScore = [currentScore;pseudoOnlineScore{1,idxFold}(:,2)];
end


dim1 = size(currentScore,1)/size(timeVector,2);
currentScore = reshape(currentScore,[dim1,size(timeVector,2),1]);
meanCurrentScore = mean(currentScore,1);
stdCurrentScore = std(currentScore,1);
hold on;
errorbar(timeVector,meanCurrentScore(1,:,1),stdCurrentScore(1,:,1));
ylim([0 1])
xlabel('time [s]')
ylabel('probability MT')
legend('motor termination')%,'threshold 50%','stop-times')


end
