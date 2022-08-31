function [axon_file_path] = abf_path()

abf_dir_file_location = fileparts(which('set_abf_directory.m'));
abf_dir_file_location = strrep(abf_dir_file_location,'\','/');

try
    load([abf_dir_file_location '/abf_directory.mat'])
catch
    disp('    -abf_path function error.')
    disp('    -you need to set the abf files directory using set_abf_directory.')
    return
end

paths = genpath(abf_directory);

if ispc
    paths = strsplit(paths,{';'})';
else
    paths = strsplit(paths,{':'})';
end

currentSplitPath = strsplit(pwd,{'\','/'});
splitFolderName = strsplit(currentSplitPath{end},'__');
axonFile = splitFolderName{end};

for i = 1:length(paths)
    list = dir(paths{i});
    names = {list.name};
    index = find(contains(names,axonFile)==1);
    if length(index) > 0
        axon_file_path = [strrep(paths{i},'\','/') '/' names{index}];
        break
    end
    if i == length(paths)
        disp('    -could not find abf file.')
    end
end
end