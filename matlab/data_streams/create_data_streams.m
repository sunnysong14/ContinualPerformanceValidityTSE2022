function create_data_streams()
% Usage
% ---------
% This script is to create the training and test data streams given a waiting
% time value. 
% 
% OUTPUT
%   Data_tst_st: data stream for jit-sdp model tst. It remains the same for
%   dif waiting time omega for a given dataset.
% 
%   Data_trn_st: data stream for jit-sdp model trn. For a given dataset,
%   dif omega leads to dif trn tmstamps and ultimately different amount of
%   label noise. Particularly, to train a jit-sdp model, 
%       * def data is used MIN(omega, VL) days after receive.
%       * non-def data is used omega days after receive it.
% 
% Liyan on 2019/10
% 

% load the data
data_name = 'brackets';
dir_data = '../data/';
data_flnm = [dir_data, data_name,'.csv'];
Data = xlsread(data_flnm);
[time_commit, XX, YY, VL] = deal(...
    Data(:,1), Data(:,2:end-2), Data(:,end-1), Data(:,end));

% create data stream for testing, [time, X, y], y is the true label
data_stream_test = [time_commit, XX, YY];
flnm_test = [dir_data, lower(data_name), '_test.csv'];
my_precise = 14;  % .csv precision
my_dlmwrite(flnm_test, data_stream_test, my_precise);

% create data stream for training, [time, X, y*], y* is the observed label
wait_days = 90;
[label_defect, label_clean] = deal(1, 0);
% The first available training data with y*=1 comes at MIN(wait_days, VL)
% days after its commit time. 
is_defect = (YY == label_defect);
time_commit_defect = time_commit(is_defect);
[X_defect, VL_defect] = deal(XX(is_defect,:), VL(is_defect)); 

% training data with y=1 may suffer from label noise if "VL > wait_days",
% so create such noisy training instances.
Y_defect = YY(is_defect); 
Y_defect(VL_defect > wait_days) = label_clean;
% compute the time when defect-inducing training data become available
delay_time_defect = days2timestamps(min(VL_defect, wait_days));
time_defect_train = time_commit_defect + delay_time_defect;

% training data with y=0 become available wait_days after their commit time
% Note that actual clean instances are noise-free. 
is_clean = (YY == label_clean);
time_commit_clean = time_commit(is_clean);
[X_clean, Y_clean] = deal(XX(is_clean,:), YY(is_clean));
% compute the time when clean training data become available
delay_time_clean = days2timestamps(repmat(...
    wait_days, size(time_commit_clean)));
time_clean_train = time_commit_clean + delay_time_clean;        

% create the data stream for training, [time, X, y*]
data_stream_train = [
    time_defect_train, X_defect, Y_defect; 
    time_clean_train, X_clean, Y_clean];
[~, sort_id] = sort(data_stream_train(:,1), 'ascend');
data_stream_train_sort = data_stream_train(sort_id,:);
% print
flnm_train = [dir_data, lower(data_name), '_train_wait_days',...
    num2str(wait_days), '.csv'];
fh = fopen(flnm_train, 'w+');
fprintf(fh, '\n');
fclose(fh);
my_dlmwrite(flnm_train, data_stream_train_sort, my_precise);

fprintf(['\nResult is printed to ', flnm_test, ...
    '\n and ', flnm_train, '\n']);
end
