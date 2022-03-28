function [eval_times_actual, y_eval_actual, y_pred_actual_mat, VLs_eval_actual, ...
    eval_times_surrogate, y_eval_surrogate, y_pred_surrogate_mat, VLs_eval_surrogate] ...
    = lookup_required_infos(data_name, wait_days_train, wait_days_evaluate, ...
    seed_lst)
% 
% Look up current and surrogate predicted labels across all seeds.
% This is the first step to answer RQ2 and RQ3.
% 
% Liyan Song on Nov.2019 and July 2020
% 

% setup in Python and the paper
total_eval_steps = 5000;

% the evaluation data stream
flnm_eval = ['../data/', data_name, '.csv'];  % with VL
data_stream_eval = xlsread(flnm_eval);  % (ts, X, y, vl)
times_eval = data_stream_eval(:,1);
Data_eval = data_stream_eval(:,1:end-1);  % (ts, X, y)
VLs_eval = data_stream_eval(:,end);

% the training data streams
flnm_train = ['../data/', data_name, '_train_wait_days', ...
    num2str(wait_days_train), '.csv'];
data_stream_train = xlsread(flnm_train);  % (ts, X, y)
train_times = data_stream_train(:,1);

% actual evaluation steps
test_time_end = times_eval(total_eval_steps);
is_eval_actual = times_eval <= test_time_end;
eval_times_actual = times_eval(is_eval_actual);
y_eval_actual = Data_eval(is_eval_actual, end);
VLs_eval_actual = VLs_eval(is_eval_actual); % to comp Y_star_ts (outside)

% surrogate evaluation steps
is_eval_surrogate = times_eval <= ...
    test_time_end - days2timestamps(wait_days_evaluate);
eval_times_surrogate = times_eval(is_eval_surrogate);
y_eval_surrogate = Data_eval(is_eval_surrogate, end);
VLs_eval_surrogate = VLs_eval(is_eval_surrogate); % to comp Y_star_ts (outside)

% get the best para: (theta_bst, M_bst). The process is the same to the
% case of the practical scenario.
dir_result = '../rslt.python/';
flnm_para_bst = [dir_result, 'para.bst/', num2str(wait_days_train), 'd/', ...
    data_name];
if isfile(flnm_para_bst)
    para_bst_arr = load(flnm_para_bst); % core
else
    print(['para_bst does not exsit in %s.', flnm_para_bst]);
    error(['The best parameter setting has NOT been calculated yet.',...
        'Please adopt Python.code to run and return there']); 
end
[theta_bst, M_bst] = deal(para_bst_arr(1), para_bst_arr(2));

% y_pre_actual and y_pre_surrogate across all 30 seeds, (time, seed)
y_pred_actual_mat = nan*ones(length(y_eval_actual), length(seed_lst));
y_pred_surrogate_mat = nan*ones(length(y_eval_surrogate), length(seed_lst));
for ss = 1:length(seed_lst)
    seed = seed_lst(ss);
    seed_py = seed - 1; % adapt to python numbering
    
    dir_rslt_eval_wtt = [dir_result, 'rslt.save/', data_name, '/', num2str(wait_days_train), 'd/',...
        'theta', num2str(theta_bst), '_M', num2str(M_bst), '/T',num2str(total_eval_steps), ...
        '/evaluation_wait_time/result.s', num2str(seed_py), '/'];

    % get all existing training timestamps
    my_file_infos = dir(dir_rslt_eval_wtt);
    dir_index = [my_file_infos.isdir]'; % return [] if no file in the dir
    if isempty(dir_index)
        error('Results should be computed via main_jit_sdp.sdp_best_para');
    end
    file_names_lst = {my_file_infos(~dir_index).name}';  % exclude invalid
    % It happens sometimes that #available_train_times < #train_times
    % Reason: two training examples are used to updata the model at once 
    % whilst no novel test example becomes available between them.
    available_train_times = str2num(cell2mat(file_names_lst));
    
    % get current and surrogate traning timestamps 
    train_time_current = find_train_time(...
        eval_times_actual, train_times, available_train_times);
    train_time_surrogate = find_train_time(...
        eval_times_surrogate, train_times, available_train_times);

    % predicted labels at current and surrogate time steps, across seeds
    y_pred_actual = lookup_predicted_labels(...
        dir_rslt_eval_wtt, eval_times_actual, train_time_current);
    y_pred_surrogate = lookup_predicted_labels(...
        dir_rslt_eval_wtt, eval_times_surrogate, train_time_surrogate);
    y_pred_actual_mat(:,ss) = y_pred_actual;
    y_pred_surrogate_mat(:,ss) = y_pred_surrogate;
end

end
