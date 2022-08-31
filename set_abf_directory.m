function set_abf_directory(abf_directory)
save_dir = fileparts(which('set_abf_directory.m'));
save_dir(strfind(save_dir,'\')) = '/';
save([save_dir '/abf_directory.mat' ],'abf_directory')
end