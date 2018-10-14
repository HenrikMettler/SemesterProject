function [c_train_err, std_c_train_err, c_test_err, std_c_test_err] = myFeatureSelection(allFeatures,fisherInd,TLabels, maxFeat,stepFeat,type,fold,runName)
    n = 1;%counter
    N = maxFeat/stepFeat;
    c_test_err = zeros(1,N);
    c_train_err = zeros(1,N);
    std_c_train_err = zeros(1,N);
    std_c_test_err = zeros(1,N);
        for f = 1:stepFeat:maxFeat
            indexes = fisherInd(1:f);%look for the first f best features
            newFeatures = allFeatures(:,:,indexes);%only the features selected
            [class_train_error_linear,class_test_error_linear,~] = ...
            helperFunctions.MyCrossValidation(newFeatures,TLabels,type,fold,[],[]);
            c_test_err(n)= mean(class_test_error_linear);
            c_train_err(n) = mean(class_train_error_linear);
            std_c_test_err(n) = std(class_test_error_linear);
            std_c_train_err(n) = std(class_train_error_linear);
            n = n+1;
        end
    figure
    errorbar(c_test_err, std_c_test_err,'-ro', 'LineWidth',1)
    hold on
    errorbar(c_train_err, std_c_train_err,'-bo','LineWidth',1);
    legend('Testing','Training')
    t = [type ' classifier - Incorporating features - Subject: ', runName];
    title(t)
    xlabel('Number of features selected')
    ylabel('Error')
end

