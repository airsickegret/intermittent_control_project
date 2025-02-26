%% Analyze RS Data
% RS center-out - rs1050225_clean_SNRgt4 located in W:\nicho\ANALYSIS\rs1050225_MI
% RS RTP - rs1050211_clean_spikes_SNRgt4 located in W:\nicho\ANALYSIS\rs1050211
subject = 'RS';
% subject_filepath = '\\prfs.cri.uchicago.edu\nicho-lab\nicho\ANALYSIS\rs1050225_MI\rs1050225_clean_SNRgt4';
subject_filepath = '\\prfs.cri.uchicago.edu\nicho-lab\nicho\ANALYSIS\rs1050211\rs1050211_clean_spikes_SNRgt4';
num_states_subject = 8;
if contains(subject_filepath,'1050225')
    task = 'CO';
elseif contains(subject_filepath,'1050211')
    task = 'RTP';
end
bin_size = .050; %s
% bad_trials = [2;92;151;167;180;212;244;256;325;415;457;508;571;662;686;748];
bad_trials = [];
move_only = 0;
muscle_lag = .100; %seconds
% Scripts to run:

%% Structure Spiking Data
[data,cpl_st_trial_rew,bin_timestamps] = nicho_data_to_organized_spiketimes_for_HMM(subject_filepath,bad_trials,task,bin_size,move_only,muscle_lag);

%% Build and Run Model
% [trInd_train,trInd_test,hn_trained,dc,seed_to_train] = train_and_decode_HMM(data,num_states_subject,[],[],0);

%% Save Model
% save(strcat(subject,'_HMM_classified_test_data_and_output_',num2str(num_states_subject),date))
%% Prepare Kinematic Data
[data] = processing_kinematics(subject_filepath,cpl_st_trial_rew,data,muscle_lag);
%% Process HMM output
% [dc_thresholded] = censor_and_threshold_HMM_output(dc);

%% Create Snippets and Plot **everything**
% [trialwise_states] = segment_analysis(num_states_subject,trInd_test,dc_thresholded,bin_timestamps,data,subject);
%
% trials_to_plot = 1:5;
% plot_single_trials(trialwise_states,num_states_subject,subject,trials_to_plot,task)
%
% num_segments_to_plot = 25;
% [segmentwise_analysis] = plot_segments(trialwise_states,num_states_subject,trInd_test,subject,num_segments_to_plot,task);
%% normalized segments

% [segmentwise_analysis] = normalize_state_segments(segmentwise_analysis,subject,task,num_states_subject);

%% Save Result
if move_only == 1
    save('RSCO_move_window')
elseif strcmp(task,'RTP')
    save('RS_RTP')
else
    save(strcat(subject,'_HMM_analysis_',num2str(num_states_subject),'_states_',date))
end