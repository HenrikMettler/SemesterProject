function plotRandomForestPseudoOnlineClassification(pseudoOnlineScore,pseudoOnlineWindow,psdParam)

startingPoint = pseudoOnlineWindow(1) + psdParam.windowSize;
timeVector = startingPoint:1/16:pseudoOnlineWindow(2);
timeVector = timeVector(2:end);


dim1 = size(pseudoOnlineScore,1)/size(timeVector,2);
pseudoOnlineScore = reshape(pseudoOnlineScore(:,2),[dim1,size(timeVector,2),1]);
meanCurrentScore = mean(pseudoOnlineScore,1);
stdCurrentScore = std(pseudoOnlineScore,1)/2;
hold on;
errorbar(timeVector,meanCurrentScore(1,:,1),stdCurrentScore(1,:,1));
ylim([0 1])
xlabel('time [s]')
ylabel('probability MT')
legend('motor termination')%,'threshold 50%','stop-times')


end