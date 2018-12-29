function plotPseudoOnlineClassification(pseudoOnlineScore,pseudoOnlineWindow,multitaperWindowSize)

startingPoint = pseudoOnlineWindow(1) + multitaperWindowSize;
timeVector = startingPoint:1/16:pseudoOnlineWindow(2);
timeVector = timeVector(2:end);

% for idxSp = 1:size(pseudoOnlineScore,2)
%     currentScore = pseudoOnlineScore{1,idxSp};
%     dim1 = size(currentScore,1)/size(timeVector,2);
%     currentScore = reshape(currentScore,[dim1,size(timeVector,2),2]);
%     meanCurrentScore = mean(currentScore,1);
%     stdCurrentScore = std(currentScore,1);
%     subplot(2,5,idxSp)
%     hold on;
%     errorbar(timeVector,meanCurrentScore(1,:,1),stdCurrentScore(1,:,1));
%     %plot(timeVector,currentScore(1:size(timeVector,2),1));
%     %plot('stopline');
%     hold off;
%     ylim([0 1])
%     xlabel('time [s]')
%     ylabel('probability MT')
%     legend('motor termination with std')%,'threshold 50%','stop-times')

% end
%
% figure (11)
%
currentScore = []; 
for idxFold = 1:size(pseudoOnlineScore,2)
    currentScore = [currentScore;pseudoOnlineScore{1,idxFold}(:,1)];
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
