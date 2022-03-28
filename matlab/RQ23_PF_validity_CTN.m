% For RQ2 and RQ3: Compute the validity of continuous predictive
% performance procedure in terms of (evaluation and training) label noises
% and (evaluation and training) waiting times, respectively. 
% 
% After this, one can adopt statistical analysis methods such as ANOVA and
% linear regression analyses to complete RQ2 and RQ3, as presented in
% Sections 8.2 and 8.3.
% 
% Liyan Song in Dec.2019, cleaned in March 2022
% 

clear; clc

% setup
data_name = 'brackets';

% Note that one has to run the python code beforehand to get all the
% prediction results in order to run this script to gain the FP validities.
% The full experimental settings are as follows:
% train_wait_days_lst = sort([15, 30, 60, 90]);
% eval_wait_days_lst = sort([15, 30, 60, 90]);
% Nevertheless, to demonstrate the use of this script and show the computed
% PF validities, one can run the below simplified setup.
train_wait_days_lst = sort([15, 30]);
eval_wait_days_lst = sort([15, 30, 60, 90]);

% To simulate the result of the TSE'22 paper, we need to run 30 times with
% "seed_lst = (1:30)';". While it will cost quite a long time. To have a
% quick impression on the empirical PF validities in terms of label noises
% (for RQ2) and waiting times (for RQ3), we run 2 times in this script.
seed_lst = [1, 2];

% RQ2: (eval_noise, train_noise, pf_validity_noise)
RQ2_content = [];
% RQ3: (eval_waiting_time, train_waiting_time, pf_validity_waiting_time)
RQ3_content = [];
for tn = 1:length(train_wait_days_lst)
    train_wait_days = train_wait_days_lst(tn);
    for tt = 1:length(eval_wait_days_lst)
        eval_wait_days =  eval_wait_days_lst(tt);
        
        % the principle of the online evaluation scheme, see Fig.4
        if train_wait_days >= eval_wait_days
            fprintf(['PF validities associated to eval_wait_days=%d ', ...
                'and train_wait_days=%d are running...\n'], ...
                eval_wait_days, train_wait_days)
            
            % get time and label informations
            [eval_times_actual, y_true_actual, y_pred_actual_mat, ...
                VLs_eval_actual, eval_times_surrogate, ...
                y_true_surrogate, y_pred_surrogate_mat, VLs_eval_surrogate] ...
                = lookup_required_infos(data_name, ...
                train_wait_days, eval_wait_days, seed_lst);
            
            % remove invalid timestamps having no label prediction
            valid_surrogate = ~isnan(y_pred_surrogate_mat(:, 1));
            y_eval_surrogate_vld = y_true_surrogate(valid_surrogate);
            eval_times_surrogate_vld = eval_times_surrogate(valid_surrogate);
            VLs_eval_surrogate_vld = VLs_eval_surrogate(valid_surrogate);
            
            valid_current = ~isnan(y_pred_actual_mat(:, 1));
            eval_times_actual_vld = eval_times_actual(valid_current);
            eval_time_end = max(eval_times_actual_vld);

            % RQ2: (total) continuous evaluation label noise associated to
            % waiting times, Eqs.7 and 8
            eval_noise_ctn = comp_noise_practice(eval_wait_days, ...
                eval_times_actual_vld, y_eval_surrogate_vld, ...
                VLs_eval_surrogate_vld, eval_times_surrogate_vld);

            % RQ2: (total) continuous training label noise associated to
            % waiting times, Eqs.7 and 8
            train_noise_ctn = comp_noise_practice(train_wait_days, ...
                eval_times_actual_vld, y_eval_surrogate_vld, ...
                VLs_eval_surrogate_vld, eval_times_surrogate_vld);
            
            % RQ2 and RQ3: true and estimated continuous PFs throughout
            % evaluation steps in terms of G-means, Sec.4.4
            [gmean_est_surrogate, gmean_tru_surrogate, gmean_tru_actual] ...
                = comp_ctn_pf_evaluates(eval_wait_days, eval_times_surrogate, ...
                y_true_surrogate, y_pred_surrogate_mat, VLs_eval_surrogate, ...
                eval_times_actual, y_true_actual, y_pred_actual_mat);
            
            % RQ2: the validity of continuous pf performance with
            % respect to label noise, average across seeds, Eq.9
            pf_validity_noise = mean(...
                1-abs(gmean_tru_surrogate-gmean_est_surrogate));
            RQ2_content = [RQ2_content; ...
                eval_noise_ctn, train_noise_ctn, pf_validity_noise];
            
            % for RQ3: the validity of continuous pf performance with
            % respect to waiting time, average across seeds, Eq.10 
            pf_validity_wait_time = mean(...
                1-abs(gmean_tru_actual-gmean_est_surrogate));
            RQ3_content = [RQ3_content; ...
                eval_wait_days, train_wait_days, pf_validity_wait_time];
        end
    end
end
