function float_decimal = my_float_decimal(float_value, my_decimal)
% OLD name: myRound2dec
% 
% Round a float into a certain decimal.
% E.g. myRound2dec(4.5623232432, 2) --> 4.56
% 
% Liyan Song in 2019/10
% 

my_multiple = 10^my_decimal;
float_decimal = round(float_value * my_multiple) / my_multiple;
end