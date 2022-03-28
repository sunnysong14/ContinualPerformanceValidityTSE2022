function [gmean_est_surrogate, gmean_tru_surrogate, gmean_tru_actual] ...
    = comp_ctn_pf_evaluates(eval_wait_days, eval_times_surrogate, ...
    y_true_surrogate, y_pred_surrogate_mat, VLs_eval_surrogate, ...
    eval_times_actual, y_true_actual, y_pred_actual_mat)
% 
% Compute true and estimated continuous PF evaluation in terms of Gmeans.
% 
% gmean_est_surrogate, gmean_tru_surrogate, and gmean_tru_actual are in the
% format of (1, #seeds)
% 
% Liyan Song in July 2019, and cleand March 2022
% 

% for surrogate timestamps
valid_surrogate_steps = ~isnan(y_pred_surrogate_mat(:, 1));
y_pred_surrogate_mat_vld = y_pred_surrogate_mat(valid_surrogate_steps, :);
y_true_surrogate_vld = y_true_surrogate(valid_surrogate_steps);
eval_times_surrogate_vld = eval_times_surrogate(valid_surrogate_steps);
VLs_eval_surrogate_vld = VLs_eval_surrogate(valid_surrogate_steps);

% for actual timestamps
valid_current = ~isnan(y_pred_actual_mat(:, 1));
y_pred_actual_mat_vld = y_pred_actual_mat(valid_current, :);
y_true_actual_vld = y_true_actual(valid_current);
eval_times_actual_vld = eval_times_actual(valid_current);

% setup
sd_num = size(y_pred_actual_mat, 2);
[ctn_gmean_est_surrogate_tt, ctn_gmean_tru_surrogate_tt, ctn_gmean_tru_actual_tt] ...
    = deal(nan*ones(length(eval_times_actual_vld), sd_num));

% for each actual evaluation step
for tt = 1:length(eval_times_actual_vld)
    actual_eval_time = eval_times_actual_vld(tt);

    % compute timestamp of the time step ts    
    actual_time_end_tt = actual_eval_time - days2timestamps(eval_wait_days);
    available_id_tt = find(eval_times_actual_vld <= actual_time_end_tt, 1, 'last');
    
    % proceed when feasible evaluate time steps exist
    if ~isempty(available_id_tt)
        
        % compute observed labels together to save time
        [y_obv_surrogate_tt, y_tru_surrogate_tt, indexs_use_tt] = ...
            decide_obverve_labels(eval_wait_days, actual_eval_time, ...
            y_true_surrogate_vld, VLs_eval_surrogate_vld, eval_times_surrogate_vld);
            
        y_pred_surrogate_mat_tt = y_pred_surrogate_mat_vld(indexs_use_tt,:);

        % until actual timestamp
        indexs_actual = find(eval_times_actual_vld <= actual_eval_time);
        y_true_actual_tt = y_true_actual_vld(indexs_actual);
        y_pre_actual_mat_tt = y_pred_actual_mat_vld(indexs_actual,:);

        % estimated continuous PF at each evaluation step based on the 
        % surrogate time steps and observed labels, Eq.5 
        ctn_gmean_est_surrogate_tt(tt,:) = pf_evaluate_online(...
            y_obv_surrogate_tt, y_pred_surrogate_mat_tt);
        
        % estimated continuous PF at each evaluation step based on the
        % surrogate time steps, Eq.3
        ctn_gmean_tru_surrogate_tt(tt,:,:) = pf_evaluate_online(...
            y_tru_surrogate_tt, y_pred_surrogate_mat_tt);
        
        % true continuous PF at each evaluation step
        ctn_gmean_tru_actual_tt(tt,:,:) = pf_evaluate_online(...
            y_true_actual_tt, y_pre_actual_mat_tt);
    end
end% across evaluate steps

% the total estimated continuous PF across evaluation time steps based on
% surrogate time steps and observed labels, Eq.6 
gmean_est_surrogate = nanmean(ctn_gmean_est_surrogate_tt, 1);

% the total estimated continuous PF across evaluation time steps based on
% surrogate time steps, Eq.4 
gmean_tru_surrogate = nanmean(ctn_gmean_tru_surrogate_tt, 1);

% the total true continuous PF across evaluation steps, Eq.2
gmean_tru_actual = nanmean(ctn_gmean_tru_actual_tt, 1);

