%{
Usage
---------
This script is to simulate how to collect true labels of software changes
by eliminating the tail of the data stream, as they are NOT "old" enough
for us to be confident on their true labels. We can then be confident about
the true labels of the remaining software changes.

Procedure
---------
Considering a data stream with 10-year duration, the procedure implemented
in this script is as follow: 1) find the 99%-quantile of the verification
latency of defect-inducing software changes in the whole data stream. Say
the 99%-quantile value is 1.5 years. 2) eliminate the software changess
that were committed during the latter 1.5 years of the data stream. The
remaining software changes cover a period of 8.5 years and will have at
least 1.5 years to find whether they have induced any defects. 

Outcomes of this script
------------------------
This script would create the 4th column of Table 1 of the TSE'22 paper. We
have at least 99% confidence that the labeling is correct. 
Since all projects have at least 5000 software changes we are confident of
their labeling, we retained the first 5000 time steps in each software
project to investigate the four RQs of this TSE'22 paper. 
As most projects have considerably more than 5000 time steps, the actual
confidence level in the labels of their software changes would be even
higher than 99%, as more software changes at the tail of the data stream
have been removed. 
Overall, via this script, one would know to keep the first 5000 time steps
in each project to have at least 99% confidence that the labeling is
correct.

Liyan Song: songly@sustech.edu.cn
2019/8 create the script; 2022/3 cleaning the script.
%}

% info overall
CONFIG = configure();
ONEDAYSTAMP = CONFIG.ONEDAYSTAMP;
DAYSINAYEAR = CONFIG.DAYSINAYEAR;

% load the data
data_name = 'brackets';
dir_data = '../data/';
data_flnm = [dir_data, data_name,'.csv'];
Data = xlsread(data_flnm);
[time_commit, XX, YY, VL] = deal(Data(:,1), Data(:,2:end-2), Data(:,end-1), Data(:,end));

% prepare the data by cutting tails
defect_bool = YY==1;
VL_defect = VL(defect_bool);
time_defect = time_commit(defect_bool);
[time_stt, time_end] = deal(min(time_defect), max(time_defect));

% get data info
my_precision = 4;
total_years = my_float_decimal((time_end-time_stt)/ONEDAYSTAMP/DAYSINAYEAR, my_precision);
total_steps = length(time_commit);    
% get verification latency based on defect-inducing samples
trust_quantile = 0.99;
cut_days = quantile(VL_defect, trust_quantile);
cut_year = my_float_decimal(cut_days/DAYSINAYEAR, my_precision);
% find the timestamp with which the tail of the data stream should be cut
time_cut_tail = floor(time_end - ONEDAYSTAMP*cut_days);
% find the retaining timestamp
retain_years = my_float_decimal((time_cut_tail - time_stt)/ONEDAYSTAMP/DAYSINAYEAR, my_precision);
retain_steps = sum(time_commit <= time_cut_tail);

% print the analysis table
flnm = [dir_data, 'auto_analyse_project_tail.csv'];
fh = fopen(flnm, 'a+');
% title
ss1 = dir(flnm);
if ss1.bytes == 0
    fprintf(fh, repmat('%s,', 1, 7), 'project', 'year.valid', ...
        'step.valid', 'quantile', 'days.cut', 'year.remain', ...
        'steps.remain');
    fprintf(fh, '\n');
end
myformat = '%s,%0.4f,%d, %0.2f,%0.4f,%0.4f,%d,\n';
% content
my_content = [trust_quantile, my_float_decimal(cut_days,my_precision), retain_years, retain_steps];
fprintf(fh, myformat, data_name, total_years, total_steps, my_content);
fclose(fh);

fprintf(['\nResult is printed in ', flnm, '\n']);


