function instructions()
clc
disp('___________________________________________________________')
disp('***Spike Cut***')
disp('version 1.0. last updated on 3/17/2021 by Spencer T. Brown ')
disp('___________________________________________________________')
disp(' ')
disp('Welcome to Spike Cut - a MATLAB-based spike sorting program for abf files.')
disp(' ')
disp('You will need to run the following functions in order: ')
disp(' ')
disp('1. set_abf_directory')
disp('     -defines the directory where abf files will be found.')
disp('     -the function only needs to be run once.')
disp('2. load_recording')
disp('     -loads, filters, and saves the recording to the current directory.')
disp('     -the output of load_recording is a file named recording.mat which contains:')
disp('         "record" - the filtered recording')
disp('         "t" - time')
disp('         "si" - the sampling interval in microseconds')
disp('3. detect_spikes_gui')
disp('4. view_spikes')
disp('5. analyze_spikes')
disp('6. cluster_spikes')
disp('7. curate_spikes')
end