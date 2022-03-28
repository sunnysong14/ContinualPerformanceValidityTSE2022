function found_train_times = find_train_time(...
    actual_eval_time, train_times, available_train_times)
% Find the actual or surrogate training timestamps corresponding to the
% actual evaluation timestamps. 
% 
% Liyan Song in Nov.2019, cleaned in March 2022
%

found_train_times = nan * ones(size(actual_eval_time));
for tt = 1:length(actual_eval_time)    
    % get the training timestamps
    id1 = find(actual_eval_time(tt) >= train_times, 1, 'last');    
    if ~isempty(id1)
        found_train_times(tt) = train_times(id1);
        if ~ismember(found_train_times(tt), available_train_times)
            error('PLS double-check the results in Python.');
        end
    end    
end
