function noise_ctn = comp_noise_practice(wait_days, ...
    actual_times, y_surrogt, VLs_surrogt, times_surrogt)
% Compute continuous label noise levels assiciated to waiting times,
% formulated in Eqs.7 and 8 of the TSE'22 paper. 
% 
% Liyan Song in Dec.2019 and cleaned in March 2022
% 

fading_factor = 0.99;
time_start = actual_times(1) + days2timestamps(wait_days);
time_end = max(actual_times);
use_indexs = find(time_start <= actual_times & actual_times <= time_end);

noise_ctn_col = nan * ones(size(use_indexs));
for tt = 1 : length(use_indexs)
    use_1index = use_indexs(tt);
    actual_eval_time = actual_times(use_1index);
    % observed labels at surrogate time steps
    [y_obv_surrogt, y_tst_surrogt] = decide_obverve_labels(wait_days,...
        actual_eval_time, y_surrogt, VLs_surrogt, times_surrogt);
    
    % continuous label noise associated to a waiting time, Eq.7
    counts = length(y_obv_surrogt);
    fading_factor_col = fading_factor.^(( (counts-1):-1:0))';
    fenmu = sum(fading_factor_col.*y_tst_surrogt);
    fenzi = sum(abs(y_obv_surrogt - y_tst_surrogt).* ...
        fading_factor_col(:).* y_tst_surrogt);
    noise_ctn_tt = fenzi/fenmu;
    if isnan(noise_ctn_tt)  % debug
        noise_ctn_tt = 0;
    end
    noise_ctn_col(tt) = noise_ctn_tt;
end

% total continuous label noise associated to waiting times, Eq.8
noise_ctn = nanmean(noise_ctn_col);
end

