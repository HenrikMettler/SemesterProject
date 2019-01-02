function plotFeatureSelection(classError,psdMode,psdParam,classifierType)
% PLOTFEATURESELECTION 
% plots results from feature selection function
if strcmp(psdMode,'multitaper')
    imageTitle = strcat('Features selection, Param: Cl-type: ',classifierType,' psd-mode: ', psdMode, ' nTapper: ',num2str(psdParam.numberOfTappers));
else
    imageTitle = strcat('Features selection, Param: Cl-type: ',classifierType,' psd-mode: ', psdMode);
end

errorbar(classError.testError, classError.testErrorStd,'-ro', 'LineWidth',1)
hold on
errorbar(classError.trainError, classError.trainErrorStd,'-bo','LineWidth',1);
legend('Testing','Training')
title(imageTitle)
xlabel('Number of features selected')
ylabel('Error')
ylim([0,0.5])
end


