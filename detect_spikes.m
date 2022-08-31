classdef detect_spikes < handle
    
    properties (Access = private)
        
        %variables
            record = [];
            t = [];
            si = [];        
            filt_record = [];
            filt_flag = 1;
            default_high_cutoff = 50;
            default_low_cutoff = 6000;        
            z_score_threshold = 2; %default
            first_threshold = 0.5; %default
            spike_window_duration = 10000; %half window duration in microseconds
            spike_window_samples = [];
            samples_per_sec = [];
            window_duration = 1; %default
            window_samples = [];
            segment_indices = [];
            peak_locs = [];
            spike_indices = [];
            spike_times = [];
            start_index = 1;
            icon_path = '';
        
        %colors 
            pastel_red        = [223 60 66]/255;
            paste1_blue       = [46 87 145]/255;
            pastel_light_blue = [120 162 204]/255;
            button_color      = [0.85 0.85 0.85];
        
        %figure handles
            f;
            ax1;
            alter_record_segment_h;
            detected_spikes_h;
            top_amp_threshold_h;
            bottom_amp_threshold_h;
            selected_spikes_h;
            top_threshold_h;
            bottom_threshold_h;
        
        %uicontrol handles
            data;
            x_corn = 60;
            y_corn = 20;
            x_button =720;
            m; 
            mitem;            
            select_btn;
            positive_detect_cbx;           
            negative_detect_cbx;           
            amplitude_detect_cbx;
            forward_btn;
            backward_btn;
            amp_thres_up_btn;
            amp_thres_down_btn;
            thres_up_btn;
            thres_down_btn;
            window_duration_edt;
            high_cutoff_edt;
            low_cutoff_edt;
            filter_cbx;
            diff_cbx;
            invert_cbx;
            threshold_label;
            filter_label;
            window_label;
            high_pass_label;
            low_pass_label;
            controls_label;
            properties_panel;
            
    end
    
    methods 
        
        function delete(this)
            
        end
        
        function this = detect_spikes
            try
                load('recording.mat')
            catch
                disp('    - could not load recording')
                disp('    - please run Spike.load()')
                delete(this)
            end
            
            %load data
                this.record = record;
                this.t = t/1000;
                this.si = si;
                this.spike_window_samples = round(this.spike_window_duration/this.si);
                this.samples_per_sec = round((10^6)/this.si);
                this.window_samples = round(this.samples_per_sec*this.window_duration);
            
            %create gui
                this.f = uifigure('Name','detect','WindowKeyPressFcn', @this.KeyPress);
                %set(this.f,'Resize',0);
                set(this.f,'Position',[50 200 1000 350]);
                this.ax1 = uiaxes(this.f,'Position',[25 100 950 250]);
                set(this.ax1,'TickDir','out'); 
                set(this.ax1,'TickLength',[0.003 0.003]);
                set(this.ax1, 'color', [0.97 0.97 0.97]);
                xlabel(this.ax1,'time (sec)');
                ylabel(this.ax1,'z-score');
            
            %axis ax1 handles
                this.alter_record_segment_h = plot(this.ax1,NaN,NaN,'k');
                hold(this.ax1,'on')
                this.detected_spikes_h      = plot(this.ax1,NaN,NaN,'.','Color',this.pastel_red,'MarkerSize',10);
                this.top_amp_threshold_h    = plot(this.ax1,NaN,NaN,'+','Color',this.paste1_blue,'MarkerSize',8,'LineWidth',1.1);
                this.bottom_amp_threshold_h = plot(this.ax1,NaN,NaN,'+','Color',this.paste1_blue,'MarkerSize',8,'LineWidth',1.1);
                this.selected_spikes_h      = plot(this.ax1,NaN,NaN,'o','Color',this.pastel_red);
                this.top_threshold_h        = plot(this.ax1,NaN,NaN,'-','Color',[0.5 0.5 0.5]);
                this.bottom_threshold_h     = plot(this.ax1,NaN,NaN,'-','Color',[0.5 0.5 0.5]);
                
            %properties panel
            
                this.properties_panel = uipanel(this.f,'Title','options:','FontSize',12,...
                     'BackgroundColor', 'white' ,'BorderType' , 'none',...
                     'Position',[65 5 300 100], ...
                     'AutoResizeChildren','on');
                 
            %menu -need to set up function
                this.m     = uimenu(this.f,'Text','&File');
                this.mitem = uimenu(this.m,'Text','&save');
                this.mitem.MenuSelectedFcn = @this.menu_save;
                
            %buttons
                this.select_btn = uibutton(this.f,'push','Position',[this.x_corn+this.x_button this.y_corn+30 90 25],'Text', 'select',...
                    'ButtonPushedFcn', @(select_btn,event) this.select_ButtonPushed(select_btn,this.ax1),'BackgroundColor',this.pastel_light_blue);

                this.forward_btn = uibutton(this.f,'push','Position',[this.x_corn+this.x_button+48 this.y_corn 42 25],'Text', '→',...
                    'ButtonPushedFcn', @(forward_btn,event) this.forward_ButtonPushed(forward_btn,this.ax1),'BackgroundColor',this.button_color,'FontWeight','bold');

                this.backward_btn = uibutton(this.f,'push','Position',[this.x_corn+this.x_button this.y_corn 42 25],'Text', '←',...
                    'ButtonPushedFcn', @(backward_btn,event) this.backward_ButtonPushed(backward_btn,this.ax1),'BackgroundColor',this.button_color,'FontWeight','bold');

                this.amp_thres_up_btn = uibutton(this.f,'push','Position',[this.x_corn+this.x_button+150 this.y_corn+30 50 25],'Text', 'amp ↑',...
                     'ButtonPushedFcn', @(amp_thres_up_btn,event) this.amp_thres_up_ButtonPushed(amp_thres_up_btn,this.ax1),'BackgroundColor',this.button_color);

                this.amp_thres_down_btn = uibutton(this.f,'push','Position',[this.x_corn+this.x_button+150 this.y_corn 50 25],'Text', 'amp ↓',...
                     'ButtonPushedFcn', @(amp_thres_down_btn,event) this.amp_thres_down_ButtonPushed(amp_thres_down_btn,this.ax1),'BackgroundColor',this.button_color);

                this.thres_up_btn = uibutton(this.f,'push','Position',[this.x_corn+this.x_button+95 this.y_corn+30 50 25],'Text', 'thres ↑',...
                     'ButtonPushedFcn', @(thres_up_btn,event) this.thres_up_ButtonPushed(thres_up_btn,this.ax1),'BackgroundColor',this.button_color);

                this.thres_down_btn = uibutton(this.f,'push','Position',[this.x_corn+this.x_button+95 this.y_corn 50 25],'Text', 'thres ↓',...
                     'ButtonPushedFcn', @(thres_down_btn,event) this.thres_down_ButtonPushed(thres_down_btn,this.ax1),'BackgroundColor',this.button_color);

            %check boxes
                this.filter_cbx = uicheckbox(this.properties_panel, 'Text','band',...
                              'Value', 0,...
                              'Position',[140 45 50 15],...
                              'ValueChangedFcn',@(filter_cbx,event) this.filter_boxChanged(filter_cbx,this.ax1));
                this.diff_cbx = uicheckbox(this.properties_panel, 'Text','diff',...
                          'Value', 0,...
                          'Position',[140 25 50 15], ...
                          'ValueChangedFcn',@(diff_cbx,event) this.filter_boxChanged(diff_cbx,this.ax1));
                      
                this.invert_cbx = uicheckbox(this.properties_panel, 'Text','invert',...
                          'Value', 0,...
                          'Position',[140 5 50 15], ...
                          'ValueChangedFcn',@(invert_cbx,event) this.filter_boxChanged(invert_cbx,this.ax1));
                      
                this.positive_detect_cbx = uicheckbox(this.properties_panel, 'Text','positive',...
                    'Value', 1,...
                    'Position',[195 45 75 15],...
                    'ValueChangedFcn',@(positive_detect_cbx,event) this.threshold_boxChanged(positive_detect_cbx,this.ax1));

                this.negative_detect_cbx = uicheckbox(this.properties_panel, 'Text','negative',...
                    'Value', 0,...
                    'Position',[195 25 75 15],...
                    'ValueChangedFcn',@(negative_detect_cbx,event) this.threshold_boxChanged(negative_detect_cbx,this.ax1));
                this.amplitude_detect_cbx = uicheckbox(this.properties_panel, 'Text','amplitude',...
                    'Value', 0,...
                    'Position',[195 5 75 15],...
                    'ValueChangedFcn',@(amplitude_detect_cbx,event) this.threshold_boxChanged(amplitude_detect_cbx,this.ax1));
     
            %edit boxes
                this.window_duration_edt = uieditfield(this.properties_panel,'numeric',...
                                      'Limits', [0.1 100],...
                                      'LowerLimitInclusive','on',...
                                      'UpperLimitInclusive','on',...
                                      'Value', 1,'Position',[85 45 45 15],...
                                      'ValueChangedFcn',@(window_duration_edt,event) this.window_numberChanged(window_duration_edt,this.ax1));
                this.high_cutoff_edt = uieditfield(this.properties_panel,'numeric',...
                                      'Limits', [0.1 1000],...
                                      'LowerLimitInclusive','on',...
                                      'UpperLimitInclusive','on',...
                                      'Value', this.default_high_cutoff,'Position',[85 25 45 15],...
                                      'ValueChangedFcn',@(high_cutoff_edt,event) this.cutoff_numberChanged(high_cutoff_edt,this.ax1)); 

                this.low_cutoff_edt = uieditfield(this.properties_panel,'numeric',...
                                      'Limits', [50 (1/(this.si/10^6))/2],...
                                      'LowerLimitInclusive','on',...
                                      'UpperLimitInclusive','on',...
                                      'Value', this.default_low_cutoff,'Position',[85 5 45 15],'ValueChangedFcn',...
                                        @(low_cutoff_edt,event) this.cutoff_numberChanged(low_cutoff_edt,this.ax1)); 

    
            %labels  
                this.threshold_label  = uilabel(this.properties_panel,'Position',[195 62 70 15],'Text', 'threshold:' );
                this.filter_label     = uilabel(this.properties_panel,'Position',[140 62 70 15],'Text', 'filter:' );
                this.window_label     = uilabel(this.properties_panel,'Position',[5 42 100 20],'Text', 'window (sec):' );
                this.high_pass_label  = uilabel(this.properties_panel,'Position',[5 22 100 20],'Text', 'high-pass:' );
                this.low_pass_label   = uilabel(this.properties_panel,'Position',[5 2 100 20],'Text', 'low-pass:' );
                this.controls_label   = uilabel(this.properties_panel,'Position',[this.x_corn+this.x_button-2 this.y_corn+59 120 15],'Text', 'selection controls:' );            
                
            %start 
                this.plot_recording(this.f);
        end
        
    end
    
    methods (Access = private)
        
        %gui controls
            function menu_save(this,src,event)
                spike_indices = this.spike_indices;
                spike_indices = sort(spike_indices);
                spike_times = this.t(spike_indices)*1000;

                endtime = this.t(end)*1000;

                del = find( (spike_times + this.spike_window_duration/(10^3) > endtime) | ...
                (spike_times - this.spike_window_duration/(10^3) < 0) );

                spike_times(del) = [];
                spike_indices(del) = [];
                [filt_record] = filter_recording(this.default_high_cutoff,this.default_low_cutoff,this.si,this.record);
                spike_records = zeros(length(spike_times),this.spike_window_samples*2);
                for i = 1:length(spike_times)
                    spike_records(i,:) = filt_record(spike_indices(i)-this.spike_window_samples:spike_indices(i) + (this.spike_window_samples - 1));
                end
                spike_record_time = ( ( (1:this.spike_window_samples*2)-1 )*this.si )/1000;
                spike_record_time = spike_record_time - ( (  (this.spike_window_samples) *this.si )/1000 );  
                si = this.si;
                save('detection_results.mat','spike_times', 'spike_indices','spike_records','spike_record_time','si');
                disp('    - detection results saved.')
                
            end

            function select_ButtonPushed(this,src,event)
                this.spike_indices(ismember(this.spike_indices,this.segment_indices)) = [];
                segment_spike_indices = this.segment_indices(this.peak_locs);
                this.spike_indices = [this.spike_indices; segment_spike_indices(:)]; 

                this.selected_spikes_h.XData = this.alter_record_segment_h.XData(this.peak_locs);
                this.selected_spikes_h.YData = this.alter_record_segment_h.YData(this.peak_locs);
                pause(0.1)
                this.forward_ButtonPushed(src);
            end

            function forward_ButtonPushed(this,src,event)
                this.start_index = this.start_index + this.window_samples;
                if this.start_index > length(this.record) - (250*1000/this.si)
                    this.start_index = length(this.record) - (250*1000/this.si); %250 ms
                end
                this.plot_recording(src);
            end

            function backward_ButtonPushed(this,src,event)
                this.start_index = this.start_index - this.window_samples;
                if this.start_index < 1
                    this.start_index = 1;
                end
                this.plot_recording(src);
            end

            function amp_thres_up_ButtonPushed(this,src,event)
                if ~this.amplitude_detect_cbx.Value
                    return
                end
                this.z_score_threshold = this.z_score_threshold + 0.25;
                this.plot_recording(src);
            end

            function amp_thres_down_ButtonPushed(this,src,event)
                if ~this.amplitude_detect_cbx.Value
                    return
                end
                this.z_score_threshold = this.z_score_threshold - 0.25;
                if this.z_score_threshold < 0.25
                    this.z_score_threshold = 0.25;
                end
                this.plot_recording(src);
            end

            function thres_up_ButtonPushed(this,src,event)
                this.first_threshold = this.first_threshold + 0.05;
                this.plot_recording(src);
            end

            function thres_down_ButtonPushed(this,src,event)
                this.first_threshold = this.first_threshold - 0.05;
                if this.first_threshold < 0.05
                    this.first_threshold = 0.05;
                end
                this.plot_recording(src);
            end

            function filter_boxChanged(this,src,event)
                this.filt_flag = 1;
                this.plot_recording(src);
            end
            
            function cutoff_numberChanged(this,src,event)
                this.filt_flag = 1;
                this.plot_recording(src);
            end 
            
            function threshold_boxChanged(this,src,event)
                switch src.Text
                    case 'positive'
                        if src.Value
                            this.negative_detect_cbx.Value  = 0;
                            this.amplitude_detect_cbx.Value = 0;
                        end
                    case 'negative'
                        if src.Value
                            this.positive_detect_cbx.Value  = 0;
                            this.amplitude_detect_cbx.Value = 0;
                        end
                    case 'amplitude'
                        if src.Value
                            this.positive_detect_cbx.Value = 0;
                            this.negative_detect_cbx.Value = 0;
                        end
                end
                
                if ~this.positive_detect_cbx.Value && ~this.negative_detect_cbx.Value && ~this.amplitude_detect_cbx.Value
                    this.positive_detect_cbx.Value = 1;
                end
                
                this.plot_recording(src);
            end
            
            function window_numberChanged(this,src,event)
                this.window_duration = this.window_duration_edt.Value;
                this.window_samples = round(this.samples_per_sec*this.window_duration);
                this.plot_recording(src);
            end
            
            
            function   this = KeyPress(this,src,event)
                switch event.Key
                     case 's'
                         this.select_ButtonPushed(src);
                     case 'rightarrow'
                         this.forward_ButtonPushed(src);
                     case 'leftarrow'
                         this.backward_ButtonPushed(src);
                      case 'uparrow'
                         if this.amplitude_detect_cbx.Value
                            this.amp_thres_up_ButtonPushed(src);
                         else
                            this.thres_up_ButtonPushed(src);
                         end
                       case 'downarrow'
                          if this.amplitude_detect_cbx.Value
                            this.amp_thres_down_ButtonPushed(src);
                         else
                            this.thres_down_ButtonPushed(src);
                         end
                end
            end
            
            
            %data flow
            function plot_recording(this,src,event)
                try 
                    this.segment_indices = this.start_index:this.start_index+this.window_samples-1;
                    test = this.t(this.segment_indices);
                catch
                    this.segment_indices = this.start_index:length(this.record);
                end

                %filter on an as needed basis
                if this.filt_flag
                    
                    this.filt_flag = 0;
                    if this.filter_cbx.Value || this.diff_cbx.Value %check box filtering
                        try 
                        [this.filt_record] = filter_recording(this.high_cutoff_edt.Value,this.low_cutoff_edt.Value,...
                            this.si,this.record);
                        catch % if high cutoff was >= low cutoff, use default filter settings
                            [this.filt_record] = filter_recording(this.default_high_cutoff,this.default_low_cutoff,...
                                this.si,this.record);
                            %reset filter edit windows
                            this.high_cutoff_edt.Value = 50;
                            this.low_cutoff_edt.Value = 6000;
                        end

                    else %default filtering
                        [this.filt_record] = filter_recording(this.default_high_cutoff,this.default_low_cutoff,...
                            this.si,this.record);
                    end

                    if this.invert_cbx.Value
                        this.filt_record = this.filt_record*-1;
                    end

                    if this.diff_cbx.Value
                        this.filt_record = diff(this.filt_record);
                        this.filt_record = [this.filt_record(1) this.filt_record];
                    end

                    %everyone gets z-scored
                    this.filt_record = zscore(this.filt_record);

                end

                alter_record_segment = this.filt_record(this.segment_indices);
                time_segment = this.t(this.segment_indices);

                this.alter_record_segment_h.XData = time_segment;
                this.alter_record_segment_h.YData = alter_record_segment;

                this.top_threshold_h.XData = [time_segment(1) time_segment(end)];
                this.top_threshold_h.YData = [this.first_threshold this.first_threshold];

                this.bottom_threshold_h.XData = [time_segment(1) time_segment(end)];
                this.bottom_threshold_h.YData = [-1*this.first_threshold -1*this.first_threshold];

                ylim(this.ax1,[-1*max(abs(alter_record_segment)) max(abs(alter_record_segment))]);
                xlim(this.ax1,[time_segment(1) time_segment(end)]);

                %detect spikes
                [pos_locs_amp, neg_pos_locs_amp, posLocs, negLocs] = detect_spikes_using_amp_thres(alter_record_segment,this.z_score_threshold,this.first_threshold,this.si);

                if this.positive_detect_cbx.Value
                    this.peak_locs = posLocs;
                elseif this.negative_detect_cbx.Value
                    this.peak_locs = negLocs;
                elseif this.amplitude_detect_cbx.Value
                    this.peak_locs = pos_locs_amp;
                end

                this.detected_spikes_h.XData = time_segment(this.peak_locs);
                this.detected_spikes_h.YData = alter_record_segment(this.peak_locs);

                if this.amplitude_detect_cbx.Value
                    x_center = zeros(length(this.peak_locs),1);
                    y_center = zeros(length(this.peak_locs),1);

                    for j = 1:length(this.peak_locs)
                        x_center(j) = ( time_segment(this.peak_locs(j)) +  time_segment(neg_pos_locs_amp(j)) )/ 2;
                        y_center(j) = ( alter_record_segment(this.peak_locs(j)) +  alter_record_segment(neg_pos_locs_amp(j)) )/ 2;
                    end

                    this.top_amp_threshold_h.XData = x_center;
                    this.top_amp_threshold_h.YData = y_center + (0.5*this.z_score_threshold);

                    this.bottom_amp_threshold_h.XData = x_center;
                    this.bottom_amp_threshold_h.YData = y_center - (0.5*this.z_score_threshold);

                else

                    this.top_amp_threshold_h.XData = NaN;
                    this.top_amp_threshold_h.YData = NaN;

                    this.bottom_amp_threshold_h.XData = NaN;
                    this.bottom_amp_threshold_h.YData = NaN;
                end


                saved_indices = 1:length(this.segment_indices);
                saved_indices = saved_indices(ismember(this.segment_indices,this.spike_indices));

                this.selected_spikes_h.XData = time_segment(saved_indices);
                this.selected_spikes_h.YData = alter_record_segment(saved_indices);
            end
    end
    
    
end
