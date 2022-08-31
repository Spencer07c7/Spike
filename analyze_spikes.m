function analyze_spikes(time_window)
    
    if nargin == 0
        disp('input a start and end time as [start end]')
        return
    end
    
    load detection_results
    
    try 
        load CxS_template
        load CxS_template_time
        template_flag = 1;
        template_logical = ismember(spike_record_time, CxS_template_time);
    catch
        template_flag = 0;
    end
    
    
    I = find(spike_record_time > time_window(1) & spike_record_time < time_window(2));
    interval_to_next_AP = [diff(spike_times) 10];
    interval_to_prev_AP = [10 diff(spike_times)];
    
    for i = 1:size(spike_records,1)
        if template_flag
            spike_conv(i,1) = sum(CxS_template.*spike_records(i,template_logical));
        end
        spike_SD(i,1) = std(spike_records(i,I));
        spike_var(i,1) = var(spike_records(i,I));
        spike_max(i,1) = max(spike_records(i,I));
        spike_min(i,1) = min(spike_records(i,I));
    end
    
    spike_mean = mean(spike_records(:,I),2);
    spike_principle_comp = pca(transpose(spike_records(:,I)),'NumComponents',3);
    
    params.mean = spike_mean(:);
    params.SD = spike_SD(:);
    params.variance = spike_var;
    params.max = spike_max(:);
    params.min = spike_min(:);
    params.pca_1 = spike_principle_comp(:,1);
    params.pca_2 = spike_principle_comp(:,2);
    params.pca_3 = spike_principle_comp(:,3);
    params.int_next_AP = interval_to_next_AP(:);
    params.int_prev_AP = interval_to_prev_AP(:);
    if template_flag
        params.temp_conv = spike_conv(:);
    end
    
    T = table(params.mean,params.SD,params.variance,params.max,params.min,...
        params.pca_1,params.pca_2,params.pca_3,params.int_next_AP,params.int_prev_AP);
    writetable(T);
%     [reduction] = run_umap('T.txt','verbose','text','n_epochs',200);
%     params.umap1 = reduction(:,1);
%     params.umap2 = reduction(:,2);
    save('params.mat','params')
    disp('    - spikes analyzed')
end
