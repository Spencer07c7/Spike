function [record] = filter_recording(high_cutoff,low_cutoff,si,record)
if high_cutoff >= low_cutoff
    error('    - high cuttoff must be lower than low cutoff.')
    return
end
sampRate = 1/((si)*(1/10^6));
low = low_cutoff/sampRate; 
high = high_cutoff/sampRate;
[b,a] = butter(2,[high low]);
record = filtfilt(b,a,record);
end