function load_recording(path, recording_channel)
    
    [record, si, recordSegmentHandle] = abfloader(path,'start',0,'stop','e');
    
    record = transpose(record(:,recording_channel));
    
    samples = 1:length(record);
    
    t = ((samples -1)*si)/(10^3);
    
    save('recording.mat','t','record','si')
    
end