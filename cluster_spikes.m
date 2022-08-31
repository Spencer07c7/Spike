classdef cluster_spikes < handle
%notes to developer:   
%remove outliers from all existing clusters and cluster_indices
%make sure selected cluster plots on top of assigned clusters

    properties (Access = private)

    %variables
        params;
        
        si;
        spike_indices;
        spike_record_time;
        spike_records;
        spike_times;
        
        cluster_indices = [];
        param_names;
        default_first_number = 0.5;
        default_last_number = 3.5;
        assigned_cluster_indices;
        assigned_cluster_names = {};
        update_cluster_flag;
        
    %figure handles
        f;
        ax1;
        ax2;
        ax3;
        all_points;
        selected_points;
        selected_spikes;
        assigned_cluster_points;
        assigned_cluster_figures;
        assigned_cluster_axes;
        default_random_spikes;
        x_corner = 10;
        y_corner = 10;
        cluster_colors = [ ]; %define later
        
    %uicontrol handles
        panel;
        time_1_edt;
        time_2_edt;
        
        menu_file;
        menu_file_item;
        
        menu_X;
        menu_X_items;
        checked_menu_X_item;
        
        menu_Y;
        menu_Y_items;
        checked_menu_Y_item;
        
        menu_tools;
        menu_tools_analyze_spikes;
        menu_tools_cut_cluster;
        menu_tools_clear_selected;
        menu_tools_assign_cluster;
        menu_tools_delete_outlier;
        
        menu_clusters;
        menu_clusters_items;
        
        tb1;
        tb2;
        tb3;
    end
    
    methods
        
        function this = cluster_spikes
            try
                load detection_results;
            catch
                disp('    - could not load data.')
            end
            
            %analyze spikes to obtain parameters
                analyze_spikes([this.default_first_number this.default_last_number]);
                
            %load saved parameters
                load 'params'
                this.param_names = fields(params);
                this.params = params;
                
            %load detection results into properties
                this.spike_record_time = spike_record_time;
                this.spike_records = spike_records;
                this.spike_indices = spike_indices;
                this.spike_times = spike_times;
                this.si = si;
                
            %set up main window
                this.f = uifigure('Name','cluster');
                set(this.f,'Position',[50 200 1000 390]);
                
            %set up axes for showing random default spikes
                this.ax1 = uiaxes(this.f,'Position',[this.x_corner this.y_corner 325 325]);
                this.tb1 = axtoolbar(this.ax1,{'zoomin','zoomout','restoreview'});
                set(this.ax1, 'color', [0.97 0.97 0.97])
                grid(this.ax1,'on')
                xlabel(this.ax1,'time (ms)')
                ylabel(this.ax1,'signal')
                
            %set up axes for plotting scatter 
                this.ax2 = uiaxes(this.f,'Position',[this.x_corner+325 this.y_corner 325 325]);
                this.tb2 = axtoolbar(this.ax2,{'zoomin','zoomout','restoreview'});
                set(this.ax2, 'color', [0.97 0.97 0.97])
                grid(this.ax2,'on')
                
            %set up axes for plotting selected spikes
                this.ax3 = uiaxes(this.f,'Position',[this.x_corner+650 this.y_corner 325 325]);
                this.tb3 = axtoolbar(this.ax3,{'zoomin','zoomout','restoreview'});
                set(this.ax3, 'color', [0.97 0.97 0.97])
                grid(this.ax3,'on')
                xlabel(this.ax3,'time (ms)')
                ylabel(this.ax3,'signal')

            %set up uicontrols
                %menu: File
                    this.menu_file = uimenu(this.f,'Text','&File');
                    this.menu_file_item = uimenu(this.menu_file,'Text','&save clusters');
                    this.menu_file_item.MenuSelectedFcn = @this.menu_save;
                
                %menu:  X
                    this.menu_X = uimenu(this.f,'Text','&x_param');
                    for i = 1:length(this.param_names)
                        this.menu_X_items.(this.param_names{i}) = uimenu(this.menu_X,'Text',['&' this.param_names{i}],'Check','off');
                        this.menu_X_items.(this.param_names{i}).MenuSelectedFcn =  @this.menu_X_cbx;
                    end
                    
                    this.menu_X_items.mean.Checked = 'on'; %by default plot mean on x axis of scatter
                    this.checked_menu_X_item = 'mean';
                    
                %menu: Y
                    this.menu_Y = uimenu(this.f,'Text','&y_param');
                    for i = 1:length(this.param_names)
                        this.menu_Y_items.(this.param_names{i}) = uimenu(this.menu_Y,'Text',['&' this.param_names{i}],'Check','off');
                        this.menu_Y_items.(this.param_names{i}).MenuSelectedFcn =  @this.menu_Y_cbx;
                    end
                    
                    this.menu_Y_items.SD.Checked = 'on'; %by default plot SD on on y axis of scatter
                    this.checked_menu_Y_item = 'SD';
                    
                %menu: tools    
                    this.menu_tools = uimenu(this.f,'Text','&tools');
                    
                    %analyze spikes
                    this.menu_tools_analyze_spikes = uimenu(this.menu_tools,'Text','&analyze spikes');
                    this.menu_tools_analyze_spikes.MenuSelectedFcn = @this.menu_analyze_spikes_callback;
                    
                    %cut cluster
                    this.menu_tools_cut_cluster = uimenu(this.menu_tools,'Text','&cut cluster');
                    this.menu_tools_cut_cluster.MenuSelectedFcn = @this.menu_cut_cluster_callback;
                    
                    %clear selected
                    this.menu_tools_clear_selected = uimenu(this.menu_tools,'Text','&clear selected');
                    this.menu_tools_clear_selected.MenuSelectedFcn = @this.menu_clear_selected_callback;
                    
                    %assign cluster
                    this.menu_tools_assign_cluster = uimenu(this.menu_tools,'Text','&assign cluster');
                    this.menu_tools_assign_cluster.MenuSelectedFcn = @this.menu_assign_cluster_callback;
                    
                    %delete outlier
                    this.menu_tools_delete_outlier = uimenu(this.menu_tools,'Text','&delete outlier');
                    this.menu_tools_delete_outlier.MenuSelectedFcn = @this.menu_delete_outlier_callback;
                    
                %menu: clusters 
                    this.menu_clusters = uimenu(this.f,'Text','&clusters');
                  
                %uipanel 
                    this.panel = uipanel(this.f,'Title','time window:','FontSize',12,...
                         'BackgroundColor','white',...
                         'Position',[this.x_corner+50 this.y_corner+330 200 45],...
                         'AutoResizeChildren','off');
                    this.time_1_edt = uieditfield(this.panel,'numeric',...
                          'Limits', [this.spike_record_time(1) this.spike_record_time(end)],...
                          'LowerLimitInclusive','on',...
                          'UpperLimitInclusive','on',...
                          'Value', this.default_first_number,'Position',[10 5 50 15]); 
                    this.time_2_edt = uieditfield(this.panel,'numeric',...
                          'Limits', [this.spike_record_time(1) this.spike_record_time(end)],...
                          'LowerLimitInclusive','on',...
                          'UpperLimitInclusive','on',...
                          'Value', this.default_last_number,'Position',[70 5 50 15]); 
                  
            %plot scatter data placeholders
                this.all_points = plot(this.ax2,NaN,NaN,'.','color',[0 0 0],'MarkerSize',5);
                hold(this.ax2, 'on' )
                this.selected_points = plot(this.ax2, NaN, NaN ,'.','color',[0.85 0 0],'MarkerSize',5);
                
            %plot selected spikes placeholder
                this.selected_spikes = plot(this.ax3,NaN,NaN,'k','LineWidth',0.25);
                
            %plot random set of 500 spikes from dataset for viewing and
            %determing analysis time window for user.
                if size(this.spike_records,1) < 500
                    number_spikes_to_plot = size(this.spike_records,1);
                else
                    number_spikes_to_plot = 500;
                end
                indices_to_plot = round(rand(1,number_spikes_to_plot)*size(this.spike_records,1));
                indices_to_plot(indices_to_plot < 1) = [];
                
                this.default_random_spikes = plot(this.ax1,this.spike_record_time,this.spike_records(indices_to_plot,:),'LineWidth',0.25);
                
                this.update_plots();
        end
        
    end
    
    methods (Access = private)
        
        %menu: tools callbacks---------------------------------------------
            
            %analyze spikes
            function menu_analyze_spikes_callback(this,src,event)

                analyze_spikes([this.time_1_edt.Value this.time_2_edt.Value])
                load params
                this.params = params;
                this.update_plots();

            end
            
            %cut cluster
            function menu_cut_cluster_callback(this,src,event)
               
                this.menu_X.Enable = 'off';
                this.menu_Y.Enable = 'off';
                this.menu_tools.Enable = 'off';
                this.menu_clusters.Enable = 'off';
                this.menu_file.Enable = 'off';
                
                zoom(this.f, 'off');
                
                this.cluster_indices = [];

                polygon = drawpolygon(this.ax2,'LineWidth',0.25,'MarkerSize',2);
                polygon_coord = polygon.Position;

                in = inpolygon(this.params.(this.checked_menu_X_item),this.params.(this.checked_menu_Y_item),polygon_coord(:,1),polygon_coord(:,2)); 

                this.cluster_indices = find(in == 1);

                if length(this.cluster_indices) > 0 %if spikes exist within the polygon 
                    plot_indices = choose_random_indices(this,this.cluster_indices);
                    this.selected_spikes = plot(this.ax3, this.spike_record_time, this.spike_records(plot_indices,:),'Color',[0.85 0 0],'LineWidth',0.25);
                end

                delete(polygon);
                
                this.menu_X.Enable = 'on';
                this.menu_Y.Enable = 'on';
                this.menu_tools.Enable = 'on';
                this.menu_clusters.Enable = 'on';
                this.menu_file.Enable = 'on';
                
                this.update_plots();
                
            end            
            
            %clear selected
            function menu_clear_selected_callback(this,src,event)
                
                this.cluster_indices = [];
                this.selected_points.XData = NaN;
                this.selected_points.YData = NaN;
                delete(this.selected_spikes);
                
            end
            
            %assign cluster
            function menu_assign_cluster_callback(this,src,event)
                this.menu_tools_delete_outlier.Enable = 'off';
                
                if isempty(this.cluster_indices)
                    disp('    - no spikes selected for assignment.')
                    return
                end
                
                name = inputdlg({'cluster name'},...
                              'cluster name', [1 50]); 
                          
                local_cluster_name = reformat_cluster_name(this,name{1});  
                local_cluster_name = ['clust_' local_cluster_name];
                
                this.assigned_cluster_names = [this.assigned_cluster_names; local_cluster_name];
                
                this.assigned_cluster_indices.(local_cluster_name) = this.cluster_indices;
                
                this.assigned_cluster_points.(local_cluster_name) = plot(this.ax2,NaN,NaN,'.');
                
                this.menu_clusters_items.(local_cluster_name) = uimenu(this.menu_clusters,'Text',['&' local_cluster_name],'Check','off');
                this.menu_clusters_items.(local_cluster_name).MenuSelectedFcn =  @this.menu_plot_cluster;

            end
            
            %delete outlier
            function menu_delete_outlier_callback(this,src,event)
                
                if isempty(this.cluster_indices)
                    disp('    - no spikes selected for assignment.')
                    return
                end

                this.spike_indices(this.cluster_indices) = [];
                this.spike_times(this.cluster_indices) = [];
                this.spike_records(this.cluster_indices,:) = [];

                spike_times = this.spike_times;
                spike_indices = this.spike_indices;
                spike_records = this.spike_records;
                si = this.si;
                spike_record_time = this.spike_record_time;
                
                save('detection_results.mat','spike_times', 'spike_indices','spike_records','spike_record_time','si');
                disp('    - detection results saved.')
                
                %need to update cluster indices for each assigned cluster
                analyze_spikes([this.time_1_edt.Value this.time_2_edt.Value]);
                load params
                this.params = params;
                this.menu_clear_selected_callback(src);
                this.update_plots();

            end

        
    %menu: clusters--------------------------------------------------------
        
        %plot clusters
        function menu_plot_cluster(this,src,event)
            
            local_cluster_name = strrep(src.Text,'&','');
            
            if this.menu_clusters_items.(local_cluster_name).Checked
                
                this.menu_clusters_items.(local_cluster_name).Checked = 'off';
                
                this.assigned_cluster_points.(local_cluster_name).XData = NaN;
                this.assigned_cluster_points.(local_cluster_name).YData = NaN;
                
                delete(this.assigned_cluster_figures.(local_cluster_name));
                
            else
                
                this.menu_clusters_items.(local_cluster_name).Checked = 'on';
                this.update_cluster_flag.(local_cluster_name) = 1;
                
            end
            
            this.update_plots();
            
        end
        
    %other functions-------------------------------------------------------
        %reformat cluster name inputted by user
        function cluster_name = reformat_cluster_name(this,name)
            
            for i = 1:length(name)
                if isletter(name(i))
                    cluster_name(i) = name(i);
                elseif ~isnan(str2double(name(i)))
                    cluster_name(i) = name(i);
                elseif strcmp(name(i),'_')
                    cluster_name(i) = name(i);
                else
                    cluster_name(i) = '_';
                end
            end
            
        end
        
        %generate random indices for plotting random spikes
        function  random_indices = choose_random_indices(this,indices)
            
            random_indices = [];
            if length(indices) > 50
                I = round(rand([50 1])*length(indices));
                I(I < 1) = [];
                random_indices = indices(I);
            else
                random_indices = indices;
            end

        end
        
    %menu: X---------------------------------------------------------------
        %checkbox callback
        function menu_X_cbx(this,src,event)
            
            for i = 1:length(this.param_names)
                this.menu_X_items.(this.param_names{i}).Checked = 'off';
            end
            
            parameter = strrep(src.Text,'&','');
            this.menu_X_items.(parameter).Checked = 'on'; 
            this.checked_menu_X_item = parameter;
            this.update_plots();
            
        end
        
    %menu: Y---------------------------------------------------------------
        %checkbox callback
        function menu_Y_cbx(this,src,event)
            
            for i = 1:length(this.param_names)
                this.menu_Y_items.(this.param_names{i}).Checked = 'off';
            end
            parameter = strrep(src.Text,'&','');
            this.menu_Y_items.(parameter).Checked = 'on';        
            this.checked_menu_Y_item = parameter;
            this.update_plots();
            
        end
        
    %menu: file------------------------------------------------------------
        %save clusters
        function menu_save(this,src,event)
            
            for i = 1:length(this.assigned_cluster_names)
                
                local_cluster_name =  this.assigned_cluster_names{i};
                
                if this.menu_clusters_items.(local_cluster_name).Checked
                    
                    cluster_spike_indices = this.spike_indices(this.assigned_cluster_indices.(local_cluster_name));
                    
                    save([local_cluster_name '.mat'],'cluster_spike_indices');
                    disp(['    - ' local_cluster_name '.mat saved.'])
                    
                end
            end
            
        end
        
 
        function update_plots(this)
            
            this.all_points.XData = this.params.(this.checked_menu_X_item);
            this.all_points.YData = this.params.(this.checked_menu_Y_item);
            xlabel(this.ax2,replace(this.checked_menu_X_item,'_',' '))
            ylabel(this.ax2,replace(this.checked_menu_Y_item,'_',' '))
            
            delete(this.selected_points);

            for i = 1:length(this.assigned_cluster_names)
                
                local_cluster_name =  this.assigned_cluster_names{i};
                
                if this.menu_clusters_items.(local_cluster_name).Checked 

                    this.assigned_cluster_points.(local_cluster_name).XData = this.all_points.XData(this.assigned_cluster_indices.(local_cluster_name));
                    this.assigned_cluster_points.(local_cluster_name).YData = this.all_points.YData(this.assigned_cluster_indices.(local_cluster_name));
                    
                    %generate cluster spikes figure
                    %should only be updated when the checked clusters
                    %change.. add a flag
                    if this.update_cluster_flag.(local_cluster_name) == 1
                        
                        this.update_cluster_flag.(local_cluster_name) = 0;
                        
                        this.assigned_cluster_points.(local_cluster_name).Color = [rand(1) rand(1) rand(1)];
                        
                        this.assigned_cluster_figures.(local_cluster_name) = figure('Name',local_cluster_name);
                        this.assigned_cluster_axes.(local_cluster_name) = axes(this.assigned_cluster_figures.(local_cluster_name));
                        
                        plot_indices = choose_random_indices(this,this.assigned_cluster_indices.(local_cluster_name));
                        plot(this.assigned_cluster_axes.(local_cluster_name),...
                            this.spike_record_time, this.spike_records(plot_indices,:),'LineWidth',0.25,'Color',this.assigned_cluster_points.(local_cluster_name).Color);
                        xlabel('time (ms)')
                        ylabel('signal')
                        
                    end
                    
                end
            end
            
            this.selected_points = plot(this.ax2,this.all_points.XData(this.cluster_indices),...
                this.all_points.YData(this.cluster_indices),'.','color',[0.85 0 0],'MarkerSize',5);
    
            
        end
               
        


    end
    
    
    
end


