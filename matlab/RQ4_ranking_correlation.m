% For RQ4: compute the Kendall Tau correlation between the estimated and
% true rankings (with respect to G-means) of JIT-SDP models on each
% project.
% Given the training waiting times of 15, 30, 60 and 90 days, we will have
% four JIT-SDP models.
% 
% Liyan Song in July 2020, cleaned on March 2022
%

clear; clc

% setup
data_name = 'brackets';

% Note that one has to run the python code beforehand to get all the
% prediction results in order to run this script to gain the FP validities.
train_wait_days_lst = sort([15, 30, 60, 90]);
eval_wait_days_lst = sort([15, 30, 60, 90]);

% To simulate the result of the TSE'22 paper, we need to run 30 times with
% "seed_lst = (1:30)';". While it will cost quite a long time. To have a
% quick impression on the empirical PF validities in terms of label noises
% (for RQ2) and waiting times (for RQ3), we run 2 times in this script.
seed_lst = [1, 2];

[gmean_tru_actual, gmean_est_surrogate] = deal(...
    nan * ones(length(eval_wait_days_lst), length(train_wait_days_lst)));
% training waiting time of 90 days is excluded
Tau_corr = nan * ones(length(eval_wait_days_lst)-1, 1); 
for tt = 1:length(eval_wait_days_lst)
    eval_wait_days =  eval_wait_days_lst(tt);
    % each training waiting time corresponds to a JIT-SDP model
    for tn = 1:length(train_wait_days_lst)
        train_wait_days = train_wait_days_lst(tn);
        
        % the principle of the online evaluation scheme, see Fig.4
        if train_wait_days >= eval_wait_days
            fprintf(['Ranking correlatin associated to eval_wait_days=%d ', ...
                'and train_wait_days=%d are running...\n'], ...
                eval_wait_days, train_wait_days)
            
            % get time and label informations
            [eval_times_actual, y_true_actual, y_pred_actual_mat, ...
                VLs_eval_actual, eval_times_surrogate, ...
                y_true_surrogate, y_pred_surrogate_mat, VLs_eval_surrogate] ...
                = lookup_required_infos(data_name, ...
                train_wait_days, eval_wait_days, seed_lst);
            
            % RQ2 and RQ3: true and estimated continuous PFs throughout
            % evaluation steps in terms of G-means, Sec.4.4
            [gmean_est_surrogate_ss, ~, gmean_tru_actual_ss] ...
                = comp_ctn_pf_evaluates(eval_wait_days, eval_times_surrogate, ...
                y_true_surrogate, y_pred_surrogate_mat, VLs_eval_surrogate, ...
                eval_times_actual, y_true_actual, y_pred_actual_mat);

            % average across seeds, (eval wait time, train wait time)
            gmean_est_surrogate(tt, tn) = mean(gmean_est_surrogate_ss);
            gmean_tru_actual(tt, tn) = mean(gmean_tru_actual_ss);
        end
    end

    % Kendal Tao correlation between pf_our vs pf_cur i.t.o. wtt
    if tt < length(eval_wait_days_lst)
        valid_index = ~isnan(gmean_est_surrogate(tt, :));
        Tau_corr(tt)= corr(...
            gmean_est_surrogate(tt, valid_index)', ...
            gmean_tru_actual(tt, valid_index)', 'type','Kendall');
    end
end
