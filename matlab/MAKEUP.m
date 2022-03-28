function MAKEUP()
% This function settles up all the PATH info.

% path.codes
addpath(genpath(['.', filesep]));    
%genpath: generate a list of directories containted in this directory

% fprintf
fprintf('\nCode folders are settled up successfully.\n') 
fprintf('"%s" is the current directory.\n',pwd)

end
