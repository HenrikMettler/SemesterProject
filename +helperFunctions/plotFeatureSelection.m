function plotFeatureSelection(classError,titleMessage)
% PLOTFEATURESELECTION 
% plots results from feature selection function

errorbar(classError.testError, classError.testErrorStd,'-ro', 'LineWidth',1)
hold on
errorbar(classError.trainError, classError.trainErrorStd,'-bo','LineWidth',1);
legend('Testing','Training')
title(titleMessage)
xlabel('Number of features selected')
ylabel('Error')
ylim([0,0.5])
end


