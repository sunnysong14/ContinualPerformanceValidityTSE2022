function [y_obv, y_tru_use, indexs_use] = decide_obverve_labels(...
    wait_days, observe_time, y_true, vl_days, commit_times)
% Compute observed labels based on verification latency values and true
% labels of data instances. 
%   
% Arguments
%   wait_days - waiting time in days to observe labels
%   observe_time - the timestamp to observe instance labels
%   y_true - true labels of instances in a data stream
%   vl_days - verification latency in days
%   commit_times - the commit timestamps of instances in the data stream
%   
%   y_obv - observed labels of instances becoming available
%   y_tru_use - true labels of those available data
%  
% Liyan Song Nov.2019
% 

time_end = observe_time - days2timestamps(wait_days);
if time_end >= min(commit_times)
    % timestamps that are not later than the observed time
    indexs_use = find(commit_times <= time_end);
    y_tru_use = y_true(indexs_use);
    
    % find availabel instances
    real_wait_times = observe_time - commit_times(indexs_use);
    VL_times = days2timestamps(vl_days(indexs_use));
    wait_enough_time = real_wait_times >= VL_times;
    
    y_obv = nan*ones(length(indexs_use),1);
    % actual labels
    y_obv(wait_enough_time) = y_tru_use(wait_enough_time);
    % noisy labels 
    y_obv(~wait_enough_time) = 0;
else
    error('No data can be labeled with this waiting time')    
end

