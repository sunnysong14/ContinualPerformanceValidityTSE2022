function timestamps = days2timestamps(days)
% old name: cvtDay2_tmstamp
% Convert days to Unix timestamp. 
% 
% Liyan Song on 2019/10/30
% 

CONFIG = configure();
ONEDAYSTAMP = CONFIG.ONEDAYSTAMP;

timestamps = ceil(days * ONEDAYSTAMP);
end