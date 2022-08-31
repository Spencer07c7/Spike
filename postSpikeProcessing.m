load('detection_results')
SS_log = ones(length(spike_indices),1);
%% 
load('clust_CxS_curated')
CS_log = ismember(spike_indices,cluster_spike_indices);
CxS_times = spike_times(CS_log);
save('CxS_times.mat','CxS_times')

neither_log = zeros(length(spike_indices),1);
%% 

load('clust_TTL_updown_curated')
neither_log = ismember(spike_indices,clust_TTL_updown);

%% 
load('clust_spikelets')
spikelets_log = ismember(spike_indices,cluster_spike_indices);
%% 
%logical AND will only take spikes that are all 3 types
true_SS = SS_log & ~(CS_log | neither_log);
SS_times = spike_times(true_SS);
save('SS_times.mat','SS_times')
%%

