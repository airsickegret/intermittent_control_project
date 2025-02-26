function  [data,cpl_st_trial_rew,bin_timestamps] = nicho_data_to_organized_spiketimes_for_HMM(subject_filepath,bad_trials,task,bin_size,move_only,muscle_lag)

% load and import unsorted spiketimes for each channel
if contains(subject_filepath,'1051013') || contains(subject_filepath,'1050225')
    if strcmp(task,'RTP')        
        load(subject_filepath,'spikes','st_trial_SRT','reward_SRT','MIchans');
        
        success_trial_count = 1;
        for iTrial = 1:length(st_trial_SRT)
            % if a reward time exists between this and the next start time,
            % then it's a successful trial. put it in the list.
            if iTrial == length(st_trial_SRT)
                if reward_SRT(reward_SRT > st_trial_SRT(iTrial))
                    st_trial_SRT_success(success_trial_count) = st_trial_SRT(iTrial);
                    success_trial_count = success_trial_count + 1;
                end
            elseif reward_SRT(reward_SRT > st_trial_SRT(iTrial) & reward_SRT < st_trial_SRT(iTrial+1))
                st_trial_SRT_success(success_trial_count) = st_trial_SRT(iTrial);
                success_trial_count = success_trial_count + 1;
            end
        end
        
        cpl_st_trial_rew(:,1) = st_trial_SRT_success;
        cpl_st_trial_rew(:,2) = reward_SRT;
    elseif strcmp(task,'CO')
        if move_only == 1
            load(subject_filepath,'spikes','go_cue','stmv','endmv','reward','st_trial','MIchans','x','y');
            
            %% Doing Kinematics
            sampling_rate = 500;  
 
            dt=1/sampling_rate; % defining timestep size
            fN=sampling_rate/2;
            
            fc = 6;
            fs = sampling_rate;
            
            [b,a] = butter(6,fc/(fs/2));
            
            filt_lowpass_x = filtfilt(b,a,x(:,2)); % running lowpass filter.
            filt_lowpass_y = filtfilt(b,a,y(:,2)); % running lowpass filter.
            
            %% calculate speed/velocity/acceleration
            
            x_speed = diff(filt_lowpass_x);
            y_speed = diff(filt_lowpass_y);
            
            % velocity
            velocity = sqrt(x_speed.^2 + y_speed.^2);
                        
            success_trial_count = 1;
            for iTrial = 1:length(endmv)
                % if a reward time exists between this and the next start time,
                % then it's a successful trial. put it in the list.
                try
                    trial_start = st_trial(iTrial);
                    trial_go = go_cue(go_cue >= trial_start & go_cue <= st_trial(iTrial+1)); 
                    trial_go = trial_go(1);
                    trial_move = stmv(stmv >= trial_go & stmv <= st_trial(iTrial+1)); 
                    trial_move = trial_move(1);
                    trial_move_end = endmv(endmv >= trial_move & endmv <= st_trial(iTrial+1)); 
                    trial_move_end = trial_move_end(1);
                    trial_reward = reward(reward >= trial_move_end & reward <= st_trial(iTrial+1)); 
                    trial_reward = trial_reward(1);
                    
                    go_relative_to_start = trial_go - trial_start;
                    move_relative_to_start =  trial_move - trial_start;
                    move_end_relative_to_start =  trial_move_end - trial_start;
                    reward_relative_to_start =  trial_reward - trial_start;
                    time_relative_to_start_ms = [0:reward_relative_to_start*1000]';
                    
                    timestamps_with_muscle_lag = x(:,1) - muscle_lag;
                    
                    speed = velocity(timestamps_with_muscle_lag > (trial_start) & timestamps_with_muscle_lag < (trial_reward));

                    % resample from 500hz to 1000hz
                    speed = repelem(speed,2);

                    
                    speed_max = find(speed == max(speed));
                    speed_max_time = speed_max(1);
                    
                    speed_thresh = mean(speed(1:round(go_relative_to_start*1000))) + 6*std(speed(1:round(go_relative_to_start*1000)));
                    kin_move_time_temp = find((speed > speed_thresh) & (time_relative_to_start_ms > go_relative_to_start));
                    kin_move_time = kin_move_time_temp(1)-.1;
                 
                    times_of_speed_under_thresh_after_max = time_relative_to_start_ms((speed < speed_thresh*4) & (time_relative_to_start_ms > speed_max_time));
                    kin_end_time = times_of_speed_under_thresh_after_max(1)+.250;
                    
                    go_cue_success(success_trial_count) = trial_start + kin_move_time/1000;
                    end_mv_success(success_trial_count) = trial_start + kin_end_time/1000;
                    
                    success_trial_count = success_trial_count + 1;
                catch
                end
            end
            
            cpl_st_trial_rew(:,1) = go_cue_success';
            cpl_st_trial_rew(:,2) = end_mv_success';
        else
            load(subject_filepath,'spikes','cpl_st_trial','reward','MIchans')
            cpl_st_trial_rew(:,1) = cpl_st_trial;
            cpl_st_trial_rew(:,2) = reward;
        end
        % Establishing Center-Out Trial Direction
        load(subject_filepath,'cpl_0deg','cpl_45deg','cpl_90deg','cpl_135deg','cpl_180deg','cpl_225deg','cpl_270deg','cpl_315deg','cpl_st_trial')
        target_dir = nan(size(cpl_st_trial,1),1);
        for iTrial = 1:size(cpl_0deg,1)
            [~,closestIndex] = min(abs(cpl_st_trial - cpl_0deg(iTrial)));
            target_dir(closestIndex) = 0;
        end
        for iTrial = 1:size(cpl_45deg,1)
            [~,closestIndex] = min(abs(cpl_st_trial - cpl_45deg(iTrial)));
            target_dir(closestIndex) = 45;
        end
        for iTrial = 1:size(cpl_90deg,1)
            [~,closestIndex] = min(abs(cpl_st_trial - cpl_90deg(iTrial)));
            target_dir(closestIndex) = 90;
        end
        for iTrial = 1:size(cpl_135deg,1)
            [~,closestIndex] = min(abs(cpl_st_trial - cpl_135deg(iTrial)));
            target_dir(closestIndex) = 135;
        end
        for iTrial = 1:size(cpl_180deg,1)
            [~,closestIndex] = min(abs(cpl_st_trial - cpl_180deg(iTrial)));
            target_dir(closestIndex) = 180;
        end
        for iTrial = 1:size(cpl_225deg,1)
            [~,closestIndex] = min(abs(cpl_st_trial - cpl_225deg(iTrial)));
            target_dir(closestIndex) = 225;
        end
        for iTrial = 1:size(cpl_270deg,1)
            [~,closestIndex] = min(abs(cpl_st_trial - cpl_270deg(iTrial)));
            target_dir(closestIndex) = 270;
        end
        for iTrial = 1:size(cpl_315deg,1)
            [~,closestIndex] = min(abs(cpl_st_trial - cpl_315deg(iTrial)));
            target_dir(closestIndex) = 315;
        end
    else
        load(subject_filepath,'spikes','cpl_st_trial','reward','st_trial_SRT','reward_SRT','MIchans');
        
        success_trial_count = 1;
        for iTrial = 1:length(st_trial_SRT)
            % if a reward time exists between this and the next start time,
            % then it's a successful trial. put it in the list.
            if iTrial == length(st_trial_SRT)
                if reward_SRT(reward_SRT > st_trial_SRT(iTrial))
                    st_trial_SRT_success(success_trial_count) = st_trial_SRT(iTrial);
                    success_trial_count = success_trial_count + 1;
                end
            elseif reward_SRT(reward_SRT > st_trial_SRT(iTrial) & reward_SRT < st_trial_SRT(iTrial+1))
                st_trial_SRT_success(success_trial_count) = st_trial_SRT(iTrial);
                success_trial_count = success_trial_count + 1;
            end
        end
        
        cpl_st_trial_rew(:,1) = vertcat(cpl_st_trial,st_trial_SRT_success');
        cpl_st_trial_rew(:,2) = vertcat(reward,reward_SRT);
    end
else
    load(subject_filepath,'spikes','cpl_st_trial_rew','MIchans');
end

% getting rid of unneeded channels
spikes = spikes(MIchans);

% breaking out channels into units
for iChannel = 1:size(spikes,1)
    if iChannel == 1
        units = [spikes{iChannel}];
    else
        units = [units,spikes{iChannel}];
    end
end

% Making sure that empty channels are removed
unit_count = 1;
for iUnit = 1:size(units,2)
    if isempty(units{iUnit})
    else
        units_temp(unit_count) = units(iUnit);
        unit_count = unit_count + 1;
    end
end

%   data should be a struct array, with field 'spikecount'
%   s.t., for each i trial, data(i).spikecount is an N x T matrix,
%   where N is the number of recorded units and T is the number of time
%   bins.
%   data(i).spikecount(j,k) holds the sum of spikes (integer value) of unit
%   j at time bin k.

num_units = size(units,2);

% Create Bins
clear trial_length
clear num_bins_per_trial
clear bin_edges
clear bin_timestamps

trials = 1:size(cpl_st_trial_rew,1);
trials(bad_trials) = [];
cpl_st_trial_rew(bad_trials,:) = [];
if strcmp(task,'CO')
    target_dir(bad_trials) = [];
end
num_trials = size(trials,2);

for iTrial = 1:num_trials
    % figure out how many 50ms bins can fit in the trial
    trial_length(iTrial) = cpl_st_trial_rew(iTrial,2) - cpl_st_trial_rew(iTrial,1);
    num_bins_per_trial(iTrial) = ceil(trial_length(iTrial)/bin_size);
    
    % assigning bin edges
    for iBin = 1:num_bins_per_trial(iTrial)
        if iBin == 1
            bin_edges(iTrial,iBin,1:2) = [cpl_st_trial_rew(iTrial,1),cpl_st_trial_rew(iTrial,1)+bin_size];
            bin_timestamps{iTrial}(iBin) = cpl_st_trial_rew(iTrial,1)+.025;
        else
            bin_edges(iTrial,iBin,1:2) = [bin_edges(iTrial,iBin-1,2),bin_edges(iTrial,iBin-1,2)+bin_size];
            bin_timestamps{iTrial}(iBin) = bin_edges(iTrial,iBin-1,2)+.025;
        end
    end
end

% putting spike counts in bins.
for iTrial = 1:num_trials
    for iUnit = 1:num_units
        for iBin = 1:(sum(bin_edges(iTrial,:,1)>0))
            data(iTrial).spikecount(iUnit,iBin) = sum(units{iUnit} >  bin_edges(iTrial,iBin,1) & units{iUnit} <  bin_edges(iTrial,iBin,2));
        end
    end
    if strcmp(task,'CO')
        data(iTrial).target_direction = target_dir(iTrial);
    end
end