function analyze_spikes(time_window)
    
    load detection_results
    
    I = find(spike_record_time > time_window(1) & spike_record_time < time_window(2));
    interval_to_next_AP = [diff(spike_times) 10];
    interval_to_prev_AP = [10 diff(spike_times)];
    
    for i = 1:size(spike_records,1)
        spike_SD(i,1)  = std(spike_records(i,I));
        spike_var(i,1) = var(spike_records(i,I));
        spike_max(i,1) = max(spike_records(i,I));
        spike_min(i,1) = min(spike_records(i,I));
    end
    
    spike_mean = mean(spike_records(:,I),2);
    spike_principle_comp = pca(transpose(spike_records(:,I)),'NumComponents',3);
    
    params.mean        = spike_mean(:);
    params.SD          = spike_SD(:);
    params.variance    = spike_var;
    params.max         = spike_max(:);
    params.min         = spike_min(:);
    params.pca_1       = spike_principle_comp(:,1);
    params.pca_2       = spike_principle_comp(:,2);
    params.pca_3       = spike_principle_comp(:,3);
    params.int_next_AP = interval_to_next_AP(:);
    params.int_prev_AP = interval_to_prev_AP(:);
    
    T = table(params.mean,params.SD,params.variance,params.max,params.min,...
        params.pca_1,params.pca_2,params.pca_3,params.int_next_AP,params.int_prev_AP);
    writetable(T);

    save('params.mat','params')
    disp('- spikes analyzed')
    
end
