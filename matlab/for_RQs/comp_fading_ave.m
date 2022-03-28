function fadAve_arr = comp_fading_ave(fading_factor, streams_col)
% comp_fading_ave()
%   Compute fading average for RQ2 and RQ3. This is to compute a common
%   fading average of a data stream. 
% 
%   NOTE 
%   1. This func cannot comp noise_ctn(tt) bec it needs consider only def
%   data being more than a common fading average.
%   2. This func returns a scalar, i.e., it computes the fading average of
%   the stream_col as a whole. We need use a 'loop' if compute fading
%   average of each element of streams_col.
% 
% Arguments
%   streams_col -- contain column vectors, where lower elements in columns
%   are closer to the current time, so their fading factors are larger. 
%   Each column stream corresponds to a seed, so Vld_ctn_* can be computed
%   more efficiently.
%   fadAve_arr -- when streams_col has more than one columns, it returns a
%   row array corresponding to multiple seeds.
% 
% Liyan on 2019/11/13, 11/18 update 
%   Now it can handle multiple seeds altogether.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
tst_count_tT = size(streams_col, 1); % often use
streams_col = abs(streams_col); % NOTE abs()

% core
Fading_factor = fading_factor.^((tst_count_tT-1):-1:0)';
fenmu = sum(Fading_factor);
fenzi = sum(Fading_factor.*streams_col, 1);
fadAve_arr = fenzi./fenmu;

end%fun