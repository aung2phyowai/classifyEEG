function [perf, predicted_label, prob_estimates]= mvpa_test(Xtest,Ytest,model,measure)

% Example usage:
% [predicted_label,accuracy,prob_estimates,weights,best_lambda]= classification(Xtrain,Xtest,Ytrain,Ytest,'7','off')
%
% Inputs:
%   Xtest        = matrix of data for testing (Trials*features)
%   Ytest        = vector of test labels (Trials)
%
% Outputs:
%   predicted_label = vector of categorical labels
%   accuracy        = vector of 3 values (the 1st one is the accuracy)
%   prob_estimates  = vector of continuous values -> distance from decision boundary for each instance
%
% Author: seb.crouzet@gmail.com

% Make sure that Y is a column vector
if isrow(Ytest),  Ytest  = Ytest'; end

[predicted_label, accuracy, prob_estimates] = predict(Ytest, sparse(double(Xtest)), model);

% compute the prob estimates myself (I had issues with those given by liblinear)
prob_estimates = 1./(1+exp(-prob_estimates));

switch measure
    
    case 'accuracy'
        perf = accuracy(1);
        
    case 'dprime'        
        % Evaluate performance
        TP = sum(predicted_label(Ytest == 1) == 1);
        FN = sum(predicted_label(Ytest == 1) == 2);
        TN = sum(predicted_label(Ytest == 2) == 2);
        FP = sum(predicted_label(Ytest == 2) == 1);
        
        %perf.accuracy            = (TP+TN) / (TP+FN+FP+TN);
        
        % +1 on all to avoid Infs or NaNs (dirty trick for d' computing to not get Inf values)
        if any([TP FN TN FP]==0), TP = TP+1; FN = FN+1; TN = TN+1; FP = FP+1; end
        
        pHit = TP / (TP + FN); % True positive rate (pHit) - sensitivity
        pFA  = TN / (TN + FP); % True negative rate () - specificity
        zHit = norminv(pHit) ;
        zFA  = norminv(pFA) ;
        perf = zHit - zFA;
        
        % To use the Statistics Toolbox function
        %perf = dprime(pHit,pFA);
        
    case 'AUC'
        [~,~,~,perf] = perfcurve(Ytest,prob_estimates,1);
        
end
end