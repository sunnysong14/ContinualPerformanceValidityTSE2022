% For investigating RQ1, implement the computation of the levels of label
% noise with respect to waiting times. 
% The investigation of Sec.8.1.3 is also investigated in this script, for
% which the continuous verification latency is also implemented.
% 
% Liyan Song on Jan.2020, cleaned on March 2022
% 

clear, clc, close all

% load the data
data_name = 'brackets';
dir_data = '../data/';
data_flnm = [dir_data, data_name,'.csv'];
Data = xlsread(data_flnm);
[commit_time_all, X_all, y_tru_all, vl_days_all] = deal(...
    Data(:,1), Data(:,2:end-2), Data(:,end-1), Data(:,end));

% the factors investigated
wait_days_lst = [15; 30; 60; 90]; 
stream_len_lst = (1000:1000:5000)';
stream_len_max = max(stream_len_lst);

% 
% compute label noise in the practical scenario throughout time step
% 
fading_factor = 0.99;
noise_ctn_total_mat= zeros(length(wait_days_lst), length(stream_len_lst));
commit_time_stt = commit_time_all(1);
for ww = 1:length(wait_days_lst)
    wait_days = wait_days_lst(ww);
    % the 1st timestamp for PF validation given a waiting time
    time_stream_1st_valid = commit_time_all(find(...
        commit_time_all >= commit_time_stt + days2timestamps(wait_days), 1));

    % compute label noise in the practical scenario throughout time steps
    % this chunk is for the computational efficiency
    time_stream_end_max = commit_time_all(stream_len_max);
    % all tt-s in [t_t0, t_end_Tmax]
    steps_observe = find(time_stream_1st_valid <= commit_time_all & ...
        commit_time_all <= time_stream_end_max);
    
    T_max = max(stream_len_lst);
    [noise_ctn_tt_all, fenzi_ctn_col, fenmu_ctn_col] ...
        = deal(nan*ones(max(stream_len_lst), 1));
    for tt = 1:length(steps_observe)
        step_observe = steps_observe(tt);
        observe_time = commit_time_all(step_observe);        
        % decide observed labels ay each individual time step
        [y_obv_tt, y_tru_tt] = decide_obverve_labels(...
            wait_days, observe_time, y_tru_all, vl_days_all, commit_time_all);
        
        % the label noise associated to a waiting time continuously
        % calculated at each test step of the data stream as Eq.(7)
        fading_factors_col = fading_factor.^(((length(y_obv_tt)-1):-1:0))';
        fenmu = sum(fading_factors_col.*y_tru_tt);
        fenzi = sum(abs(y_obv_tt-y_tru_tt).*fading_factors_col.*y_tru_tt);
        noise_ctn_tt = fenzi/fenmu;
        % when no data with class 1 exists and all observed labels are
        % correct, the NaN value of label noise should be altered to 0.
        if isnan(noise_ctn_tt)
            noise_ctn_tt = 0; 
        end
        noise_ctn_tt_all(step_observe) = noise_ctn_tt;
        fenzi_ctn_col(step_observe) = fenzi;
        fenmu_ctn_col(step_observe) = fenmu;
    end
    
    % plot noise levels throughout time steps
    figure;
    xx = 1:stream_len_max;
    plot(xx, noise_ctn_tt_all, 'r.:'), grid on;
    ylabel('continuous noise level'); 
    ylim([0,1])
    title([data_name, ', ', num2str(wait_days), ' waiting days']);

    % the total impact of waiting time on label noise continuously for the
    % whole data stream, Eq.8
    for tt = 1:length(stream_len_lst)
        noise_ctn_tt = noise_ctn_tt_all(1:stream_len_lst(tt));
        noise_ctn_total_mat(ww, tt) = nanmean(noise_ctn_tt);
    end
end

% 
% For Sec.8.1.3, investigate why larger data stream associated to larger
% continuous label noise

% compute continuous verification latency levels throughout steps, Eq.14
fading_factor = 0.99;
vl_ctn_tt = nan*ones(max(stream_len_lst), 1);
for tt = 1:stream_len_max
    vl_days_tt = vl_days_all(1:tt);
    y_tru_tt = y_tru_all(1:tt);
    fading_factors_col = fading_factor.^(( (tt-1):-1:0))';
    fenmu = sum(fading_factors_col.*y_tru_tt);
    fenzi = sum(fading_factors_col.*vl_days_tt);
    vl_ctn_tt(tt) = fenzi/fenmu;
end

% the total continuous verification latency for the whole stream, Eq.15
% This procedure is to compute the correlation between the length of data
% stream and continuous verification levels, Step 1 of Sec.8.1.3
vl_ctn_total_col = nan*ones(length(stream_len_lst), 1);
for tt = 1:length(stream_len_lst)
    stream_len = stream_len_lst(tt);
    vl_ctn_stream_len = vl_ctn_tt(1:stream_len);    
    vl_ctn_total_col(tt) = nanmean(vl_ctn_stream_len);
end

