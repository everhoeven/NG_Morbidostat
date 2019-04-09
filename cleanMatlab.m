timers = timerfindall();
[r,c] = size(timers);
if(r>0)
    stop(timers);
    delete(timers);
end
clear timers
close all
clear all
clc
