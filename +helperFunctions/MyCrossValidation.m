function [class_error_training,class_error_testing,X,Y,AUC,C] = MyCrossValidation(newFeatures,TLabels,type,fold,r,c)
        class_error_training = zeros(1,fold);
        class_error_testing = zeros(1,fold);
        X = [];
        Y = [];
        AUC = [];
        S = size(newFeatures,1)/fold;
%         ST = (fold-1)*S/fold;
        for k = 1:fold
            
            %index for testing
            TestIndex = ((k-1)*S+1:k*S);
            AllIndex = 1:1:120;
            %index for training
            %index that are in allindex but not in TestIndex
            TrainIndex = setdiff(AllIndex, TestIndex);

            %Creating the folds: one single fold consists of 12 trials one after
            %the other, the test has 1 fold, the training, 9 folds
            Tr = newFeatures(TrainIndex,:,:);
            Training = zeros(size(Tr,1)*size(Tr,2),size(Tr,3));
            for i = 1:size(Tr,1)
               Training((i-1)*97+1:i*97,:) = Tr(i,:,:);
            end
  
            Te = newFeatures(TestIndex,:,:);
            Testing = zeros(size(Te,1)*size(Te,2),size(Te,3),1);
            for i = 1:size(Te,1)
               Testing((i-1)*97+1:i*97,:) = Te(i,:,:);
            end
            
            %Corresponding Labels
            %training labels
            TrLabels = TLabels(TrainIndex,:);
            for i = 1:size(TrLabels,1)
               TrainingLabels((i-1)*97+1:i*97) = TrLabels(i,:);
            end
            
            %testlabels
            TeLabels = TLabels(TestIndex,:);
            for i = 1:size(TeLabels,1)
               TestingLabels((i-1)*97+1:i*97) = TeLabels(i,:);
            end

            classifier_linear = fitcdiscr(Training,TrainingLabels,'DiscrimType',type);
            %predict label for both training and testing and save class errors
            yhat_linear_Training  = predict(classifier_linear,Training);
            [yhat_linear_Test,score]  = predict(classifier_linear,Testing);
            class_error_training(k) = helperFunctions.classerror(TrainingLabels', yhat_linear_Training);
            class_error_testing(k) = helperFunctions.classerror(TestingLabels', yhat_linear_Test);
            if isempty(r)
            else
                [FPR,TPR,~,A] = perfcurve(TestingLabels,score(:,2),1);
                X = [X,FPR];
                Y = [Y,TPR];
                AUC = [AUC; A];
            end
            if isempty(c)
            else
                 cmat = confusionmat(TestingLabels',yhat_linear_Test);
                 C(:,:,k) = cmat/sum(sum(cmat));
            end
        end
end

