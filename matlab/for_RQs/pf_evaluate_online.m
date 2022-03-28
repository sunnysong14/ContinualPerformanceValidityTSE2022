function gmean_tt = pf_evaluate_online(y_true_col, y_pred_mat)
% PF evaluation for a binary classification in an online learning scenario.
% Class 1 denotes defect-inducing and class 0 denotes clean.
% 
% Refer to [Shuo TKDE'15] paper. 
% 
% Liyan on 2019/12/19 
%

labels = [0 1]';
cond = all(ismember(unique(y_pred_mat), labels)) ...
    && all(ismember(unique(y_true_col), labels));
msg = ['Labels should be: ', num2str(labels()')];
assert(cond, msg);

% setup
fading_factor = 0.99; 
[R0, R1] = deal(nan*ones(size(y_pred_mat))); % R0-tnr, R1-tpr
[n0, n1] = deal(nan*ones(length(y_true_col),1)); % n0: #neg, n1: #pos

% for tt = 1
tt = 1;
y_true_tt = y_true_col(tt);
y_pred_tt = y_pred_mat(tt,:);  % seeds in row
correct = double(y_true_tt == y_pred_tt);
% either R1(1) or R0(1) is updated
if y_true_tt ==1
    R1(tt,:) = correct;
    n1(tt) = 1;
elseif y_true_tt == 0
    R0(tt,:) = correct;
    n0(tt) = 1;
end

% loop for tt >= 2
for tt = 2 : length(y_true_col)
    y_true_tt = y_true_col(tt);
    y_pred_tt = y_pred_mat(tt,:);  % seeds in row
    correct = double(y_true_tt == y_pred_tt);
    
    % update R0(t) and R1(t)
    if y_true_tt == 1
        if any(isnan(R1(tt-1,:)))  % if tt is the first valid time step
            R1(tt,:) = correct;
        else  % if (tt-1) is valid
            R1(tt,:) = fading_factor.*R1(tt-1,:) + (1-fading_factor).*correct;
        end
        R0(tt,:) = R0(tt-1,:);
        
    elseif y_true_tt == 0
        if any(isnan(R0(tt-1,:)))  % if tt is the first valid time step
            R0(tt,:) = correct;
        else  % if (tt-1) is valid
            R0(tt,:) = fading_factor.*R0(tt-1,:) + (1-fading_factor).*correct;
        end
        R1(tt,:) = R1(tt-1,:);        
    end
    
    % update n0(t) and n1(t)
    if isnan(n0(tt-1))  % if tt is the 1st valid time step
        n0(tt) = double(y_true_tt==0);
    else  % (tt-1) is valid
        n0(tt) = fading_factor*n0(tt-1) + (1-fading_factor)*double(y_true_tt==0);
    end
    if isnan(n1(tt-1))  % tt is the 1st valid time step
        n1(tt) = double(y_true_tt==1);
    else  % (tt-1) is valid
        n1(tt) = fading_factor*n1(tt-1) + (1-fading_factor)*double(y_true_tt==1);
    end
end

% compute various PF metrics
tpr_tt = R1;
tnr_tt = R0;
p_tt = n1;
n_tt = n0;
N_tt = p_tt + n_tt;

tp_tt = tpr_tt.*p_tt;
tn_tt = tnr_tt.*n_tt;
 
fp_tt = n_tt - tn_tt;
fn_tt = p_tt - tp_tt;

recall_tt = tpr_tt;

% pf metrics
accuracy_tt = (tp_tt+tn_tt)./N_tt;
precision_tt = tp_tt ./ (tp_tt+fp_tt);
f_measure_tt = 2.*(precision_tt.*recall_tt) ./(precision_tt+recall_tt);
gmean_tt = sqrt(tpr_tt.*tnr_tt);
gmean_tt = gmean_tt(end,:);

% evals_end = [1-tnr_tt(end,:); 1-tpr_tt(end,:); accuracy_tt(end,:); ...
%     precision_tt(end,:); f_measure_tt(end,:); gmean_tt(end,:)];
% % evals: fpr(1), fnr(2), acc(3), prec(4), fmeas(5), gmean(6)
end
