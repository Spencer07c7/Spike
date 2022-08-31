classdef Spike < handle
    
    properties (Access = private)
             
    end
    
    methods 
        
        function this = Spike
            
        end
        
        function load(this,file_path,channel)
            
            switch nargin
                case 1
                    disp('    - provide the following inputs: (file_path, channel)')
                    return;
            end
            
            load_recording(file_path,channel);
        end
        
        function detect(this)
            
            detect_spikes();
            
        end
        
        function cluster(this)
            
            cluster_spikes();
            
        end
        
        function curate(this)
            
            curate_spikes();
            
        end
        
    end
    
    methods (Access = private)
        
    end
    
    
end
