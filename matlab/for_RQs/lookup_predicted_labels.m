function y_pred_arr = lookup_predicted_labels(...
    dir_rslt_jit, evaluate_times, training_times)
% Lookup predicted labels from the results in (time, y_true, y_pred) that
% had been computed in Python at the time steps represented in
% evaluate_times, each of which uses the model created at training_times. 
% 
% This is an important implementation for the investigation of RQ2 and RQ3.
% It would take some time to find all label information.
% 
% Liyan Song on Nov.2019
%

y_pred_arr = nan * ones(size(training_times));
for tt = 1:length(training_times)
    time_test = evaluate_times(tt);
    time_train = training_times(tt);    
    % lookup at the valid training timestamps one by one
    if ~isnan(time_train)
        % load estimates, (ts,y_tru,y_pre)
        reslt_at_current_train_time = load(...
            [dir_rslt_jit, num2str(time_train)]);
        % lookup predicted labels
        id = find(reslt_at_current_train_time(:,1)==time_test, 1, 'first');
        y_pred_arr(tt) = reslt_at_current_train_time(id, end);
    end
end