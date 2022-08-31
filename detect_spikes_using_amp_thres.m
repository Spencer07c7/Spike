function [pos_spike_indices, neg_spike_indices, posLocs, negLocs] = detect_spikes_using_amp_thres(record,amplitude_threshold, first_threshold,si)

    number_of_samps_threshold = round(750/si);
    number_of_samps_half_window = round(500/si); 
    [posLocs pks] = peakseek(record,number_of_samps_threshold,first_threshold);
    [negLocs pks] = peakseek(record*-1,number_of_samps_threshold,first_threshold);
    
    pos_spike_indices = [];
    neg_spike_indices = [];
    for i = 1:length(posLocs)
        
        I = find(negLocs >= posLocs(i) - number_of_samps_half_window & negLocs <= posLocs(i) + number_of_samps_half_window);
        if length(I) == 1
            %do nothing
        elseif length(I) > 1
            localAmps = [];
            for j = 1:length(I)
                amp = abs(record(posLocs(i)) - record(negLocs(I(j))));
                localAmps = [localAmps; amp];
            end
            [maxLocalAmps maxI] = max(localAmps);
            I = I(maxI);
        elseif length(I) < 1
            continue
        end

        amp = record(posLocs(i)) - record(negLocs(I));
        if amp >= amplitude_threshold
            pos_spike_indices = [pos_spike_indices; posLocs(i)];
            neg_spike_indices = [neg_spike_indices; negLocs(I)];
        end
        
    end
    
end