classdef curate_spikes < handle
%notes to developer:   
%remove outliers from all existing clusters and cluster_indices
%make sure selected cluster plots on top of assigned clusters

    properties (Access = private)
        
        %variables
            all_spike_indices = [];
            orig_cluster_spike_indices = [];
            cluster_spike_indices = [];
            answer = [];
            half_window_samples = 2000;
            center_spike_index = [];
            t = [];
            record = [];
            cluster_filename = '';

        %figure handles
            f;
            ax1;
            record_h;
            all_spike_h;
            current_spike_h;
            cluster_spike_h;
            m;
            mitem_open;
            mitem_save;
            select_btn;
            forward_btn;
            backward_btn;
            deselect_btn;
            review_forward_btn;
            review_backward_btn;
            review_label;
            button_color =  [0.85 0.85 0.85]; 
            
    end
    
    methods
        
        function this = curate_spikes
            
            this.f = uifigure('Name','curate','WindowKeyPressFcn', @this.KeyPress);
            set(this.f,'Resize',0);
            set(this.f,'Position',[50 200 1495 350])
            this.ax1 = uiaxes(this.f,'Position',[10 10 1355 310]);
            set(this.ax1,'TickDir','out'); 
            set(this.ax1,'TickLength',[0.003 0.003])

            this.record_h = plot(this.ax1,NaN,NaN,'Color', [0 0 0]);
            hold(this.ax1,'on')
            set(this.ax1, 'color', [0.95 0.95 0.95])

            this.all_spike_h =  plot(this.ax1,NaN,NaN,'d','MarkerSize',10,'Color',[120/255, 162/255, 204/255],'LineWidth',1.1);
            this.current_spike_h = plot(this.ax1,NaN,NaN,'db','MarkerSize',10,'LineWidth',2.5,'Color',[46/255, 87/255, 145/255]);
            this.cluster_spike_h = plot(this.ax1,NaN,NaN,'.','MarkerSize',15,'Color',[223/255, 60/255, 66/255]);

            xlabel(this.ax1,'time (sec)')
            ylabel(this.ax1,'signal') 
            

            this.m = uimenu(this.f,'Text','&File','Separator','off');
            this.mitem_open = uimenu(this.m,'Text','&open');
            this.mitem_open.MenuSelectedFcn = @this.menu_open;
            this.mitem_save = uimenu(this.m,'Text','&save');
            this.mitem_save.MenuSelectedFcn = @this.menu_save;

            this.select_btn = uibutton(this.f,'push','Position',[1370 285 115 30],'Text', 'select',...
                'ButtonPushedFcn', @(select_btn,event) this.select_ButtonPushed(select_btn,this.ax1),'BackgroundColor',this.button_color,'FontWeight','bold');

            this.forward_btn = uibutton(this.f,'push','Position',[1430 251 55 30],'Text', '→',...
                'ButtonPushedFcn', @(forward_btn,event) this.forward_ButtonPushed(forward_btn,this.ax1),'BackgroundColor',this.button_color,'FontWeight','bold');

            this.backward_btn = uibutton(this.f,'push','Position',[1370 251 55 30],'Text', '←',...
                'ButtonPushedFcn', @(backward_btn,event) this.backward_ButtonPushed(backward_btn,this.ax1),'BackgroundColor',this.button_color,'FontWeight','bold');

            this.deselect_btn = uibutton(this.f,'push','Position',[1370 217 115 30],'Text', 'deselect',...
                'ButtonPushedFcn', @(deselect_btn,event) this.deselect_ButtonPushed(deselect_btn,this.ax1),'BackgroundColor',this.button_color,'FontWeight','bold');

            this.review_forward_btn = uibutton(this.f,'push','Position',[1430 153 55 30],'Text', '→',...
                'ButtonPushedFcn', @(review_forward_btn,event) this.review_forward_ButtonPushed(review_forward_btn,this.ax1),'BackgroundColor',this.button_color,'FontWeight','bold');

            this.review_backward_btn = uibutton(this.f,'push','Position',[1370 153 55 30],'Text', '←',...
                'ButtonPushedFcn', @(review_backward_btn,event) this.review_backward_ButtonPushed(review_backward_btn,this.ax1),'BackgroundColor',this.button_color,'FontWeight','bold');

            this.review_label = uilabel(this.f,'Position',[1370 184 115 20],'Text', 'review selection:' );

            
        end
        
    end
    
    methods (Access = private)   
        
        function KeyPress(this,src,event)
            
             switch event.Key

                 case 'd' 
                     this.deselect_ButtonPushed(src);
                 case 's'
                     this.select_ButtonPushed(src);
                 case 'rightarrow'
                     this.forward_ButtonPushed(src);
                 case 'leftarrow'
                     this.backward_ButtonPushed(src);
                 case 'comma'
                     this.review_backward_ButtonPushed(src);
                 case 'period'
                     this.review_forward_ButtonPushed(src);
             end
         
        end
        
        function menu_save(this,src,event)

            keep = find(this.answer == 1);
            this.cluster_spike_indices = this.all_spike_indices(keep);
            filename = replace(this.cluster_filename,'.mat','_curated.mat');
            cluster_spike_indices = this.cluster_spike_indices;
            save(filename,'cluster_spike_indices');
            disp(['    - ' filename ' saved.'])

        end
        
        function menu_open(this,src,event)

            file = uigetfile;

            if file == 0
                return
            end

            load([file])

            if exist('cluster_spike_indices','var')
                this.cluster_filename = file;
            else
                disp('    -this is not a cluster file')
                return
            end
            
            figure(this.f)
            load detection_results
            load recording
            [filt_record] = filter_recording(50,6000,si,record);
            this.record = filt_record;
            this.t = t/1000;
            this.all_spike_indices = spike_indices;
            this.orig_cluster_spike_indices = cluster_spike_indices;
            this.cluster_spike_indices = cluster_spike_indices;
            this.answer =  zeros(1,length(this.all_spike_indices));
            this.answer(ismember(this.all_spike_indices,this.cluster_spike_indices)) = 1;
            this.center_spike_index = cluster_spike_indices(1);
            this.plot_recording(src);

        end
        
        function plot_recording(this,src,event)
            drawnow;
            if this.center_spike_index-this.half_window_samples < 1
                recordIndices = 1:this.center_spike_index+this.half_window_samples;
                xLimits = [this.t(1) this.t(this.center_spike_index+this.half_window_samples)];

            elseif this.center_spike_index+this.half_window_samples > length(this.record)
                recordIndices = this.center_spike_index-this.half_window_samples:length(this.record);
                xLimits = [this.t(this.center_spike_index-this.half_window_samples) this.t(end)];

            else
                recordIndices = this.center_spike_index-this.half_window_samples:this.center_spike_index+this.half_window_samples;
                xLimits = [this.t(this.center_spike_index-this.half_window_samples) this.t(this.center_spike_index+this.half_window_samples)];

            end

            current_cluster_indices = this.cluster_spike_indices(ismember(this.cluster_spike_indices,recordIndices));
            current_all_indices = this.all_spike_indices(ismember(this.all_spike_indices,recordIndices));

            current_cluster_times = this.t(current_cluster_indices);
            current_all_times = this.t(current_all_indices);

            this.record_h.XData = this.t(recordIndices);
            this.record_h.YData = this.record(recordIndices);

            this.cluster_spike_h.XData = this.t(current_cluster_indices);
            this.cluster_spike_h.YData = zeros(length(current_cluster_indices),1);

            this.all_spike_h.XData = this.t(current_all_indices);
            this.all_spike_h.YData = zeros(length(current_all_indices),1);

            this.current_spike_h.XData = this.t(this.center_spike_index);
            this.current_spike_h.YData = 0;

            ylim(this.ax1,[-1*max(abs(this.record(recordIndices))) max(abs(this.record(recordIndices)))]);
            xlim(this.ax1,xLimits);

        end
        
        
        function select_ButtonPushed(this,src,event)

            this.answer(ismember(this.all_spike_indices,this.center_spike_index)) = 1;
            this.cluster_spike_indices = this.all_spike_indices(this.answer > 0);
            this.plot_recording(src);
            pause(0.1);
            this.forward_ButtonPushed(src);

        end
        
        function deselect_ButtonPushed(this,src,event)

            this.answer(ismember(this.all_spike_indices,this.center_spike_index)) = 0;
            this.cluster_spike_indices = this.all_spike_indices(this.answer > 0);
            this.plot_recording(src);
            pause(0.1);
            this.forward_ButtonPushed(src);

        end
        
        function forward_ButtonPushed(this,src,event)

            I = find(this.orig_cluster_spike_indices > this.center_spike_index);
            if length(I) < 1
                %do nothing
                this.plot_recording(src);
            else
               this.center_spike_index = this.orig_cluster_spike_indices(I(1));
               this.plot_recording(src);
               
            end

        end
        
        function backward_ButtonPushed(this,src,event)

            I = find(this.orig_cluster_spike_indices < this.center_spike_index);
            if length(I) < 1
                %do nothing
                this.plot_recording(src);
            else
               this.center_spike_index = this.orig_cluster_spike_indices(I(end)); 
               this.plot_recording(src);  
               
            end

        end

        function review_forward_ButtonPushed(this,src,event)

            I = find(this.cluster_spike_indices > this.center_spike_index);
            if length(I) < 1
                %do nothing
                
            else
               this.center_spike_index = this.cluster_spike_indices(I(1));
               this.plot_recording(src);
               
            end

        end
        
        function review_backward_ButtonPushed(this,src,event)

            I = find(this.cluster_spike_indices < this.center_spike_index);
            if length(I) < 1
                %do nothing
                
            else
               this.center_spike_index = this.cluster_spike_indices(I(end)); 
               this.plot_recording(src);     
               
            end

        end
        
        
    end
    
    
    
end


