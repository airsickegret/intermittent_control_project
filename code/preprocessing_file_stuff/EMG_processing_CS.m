function [trialwise_EMG] = EMG_processing_CS(session,channels_to_analyze,task,periOnPM_30k,isSuccess)
%% EMG Processing
%Steps
% 1. Record at 10k
% 2. Notch filter at 60hz
% 3. Lowpass at 1k hz (due to downsampling)
% 4. Downsample
% 5. Highpass at 10-15hz
% 6. Rectify
% 7. Lowpass (to smooth)
% 8. Format for HMM

for iChannel = 1:length(channels_to_analyze)
    if iChannel == 1
        channels_to_analyze_string = num2str(channels_to_analyze(iChannel));
    end
    channels_to_analyze_string = [channels_to_analyze_string,','];
    channels_to_analyze_string = [channels_to_analyze_string ...
        num2str(channels_to_analyze(iChannel))];
end

muscle_labels = {'FDS','Pect_Major','ECU','BiL','EDC','AD','TrLat','TrL',...
    'BiS','FCU','Brachioradialis','ECR','PD'};

params = init_paramsBreaux_CS();

trial_start_event_channel = 1;
reward_event_channel = 2;

filenameNS5 = ['Bx' session 'PM'];

filestring = [params.dataDirServer filenameNS5 '.ns4'];


convconst = 1/6562; %openNSx raw, not 'uV'

Data = openNSx(filestring, 'read', ...
    strcat('c:',channels_to_analyze_string));

%% Lowpass at 1k hz
sampling_rate = Data.MetaTags.SamplingFreq ;

dt=1/sampling_rate; % defining timestep size
fN=sampling_rate/2;

fhs=1000;           % lowpass frequency?

[b,a]=butter(2,fhs/fN);

for iChannel = 1:size(Data.Data,1)
    filt_lowpass_1k(iChannel,:) = ...
        filtfilt(b,a,double(Data.Data(iChannel,:))); % running bandpass filter.
end
%% downsample

downsample_factor = 5;

sampling_rate = sampling_rate/downsample_factor;

for iChannel = 1:size(filt_lowpass_1k,1)
    lowpassed_1k_resampled_2k(iChannel,:) = ...
        downsample(filt_lowpass_1k(iChannel,:),downsample_factor);
end
%% highpass at 10 hz
dt=1/sampling_rate; % defining timestep size
fN=sampling_rate/2;

fhs=10;           % highpass frequency filter?

[b,a]=butter(2,fhs/fN,'high');

for iChannel = 1:size(Data.Data,1)
    lo1k_resamp_hi10(iChannel,:) = ...
        filtfilt(b,a,lowpassed_1k_resampled_2k(iChannel,:)); % running bandpass filter.
end

%% Rectify
for iChannel = 1:size(Data.Data,1)
    rectified_filtered_resampled(iChannel,:) = ...
        abs(lo1k_resamp_hi10(iChannel,:));
end

%% Smooth (another lowpass)

fhs=10; % lowpass frequency

[b,a]=butter(2,fhs/fN);

for iChannel = 1:size(Data.Data,1)
    final_lowpass_data(iChannel,:) = ...
        filtfilt(b,a,rectified_filtered_resampled(iChannel,:)); % running bandpass filter.
end


%% Package for HMM

%% Bring in NEV events


% Center-out data leverages Vassilis' existing events structure to pull in
% peri-on timing for each trial, instead of relying on my half-assed binary
% events reading.



if strcmp('CO',task)
    %     startEpoch = 100;
    %     rewardEpoch = 1000;
    
    periOn_10k = round(periOnPM_30k./3);
    periOn_10k = periOn_10k(isSuccess); %only do success trials
    periOn_2k = round(periOn_10k./5);
 
    %set time period to keep
    msBeforePeriOn = 1000; msAfterPeriOn = 3500; newFS = 2000;
    iBeforePeriOn = msBeforePeriOn*newFS/1000; iAfterPeriOn = (msAfterPeriOn*newFS/1000) - 1;
    emgt = (-iBeforePeriOn:1:iAfterPeriOn)*1000/newFS; nTimePoints = numel(emgt);

    
    
    state_start_2k = periOn_2k-iBeforePeriOn;
    state_reward_2k = periOn_2k+iAfterPeriOn;

elseif strcmp('RTP',task)
    
    filestring_nev = [params.dataDirServer filenameNS5 '.nev'];
    events_nev = openNEV(filestring_nev,'noread','nosave', 'nomat');
    
    % startEpoch = 65508;
    % rewardEpoch = 65512;
    %
    
    binary_events = dec2bin(events_nev.Data.SerialDigitalIO.UnparsedData);
    binary_events = binary_events(:,12:16);
    binary_events = str2num(binary_events);
    % use dec2bin() to figure out which event is being changed or triggered with each thing
    
    startEpoch = 100;
    rewardEpoch = 1000;
    %SerialDigitalIO.UnparsedData has one entry for each occuring event.
    %SerialDigitalIO.Timestamp has the time index of these events.
    state_start = ...
        events_nev.Data.SerialDigitalIO.TimeStamp(binary_events==startEpoch);
    state_reward = ...
        events_nev.Data.SerialDigitalIO.TimeStamp(binary_events==rewardEpoch);
    state_start_2k = state_start./15;
    state_reward_2k = state_reward./15;
end

% if strcmp('180323',session)
%     binary_events = binary_events(30:end);
% end
%



% if strcmp('CO',task)
% %     for iTrial = 1:length(state_reward)
% %         state_start_temp = state_start(state_start < state_reward(iTrial));
% %         state_start_success(iTrial) = state_start_temp(end);
% %     end
% %     state_start_2k = (state_start_success./15) - 1000*2 + 1;
% %     state_reward_2k = (state_start_success./15) + 3500*2;
% elseif strcmp('RTP',task)
% end

%%
for iTrial = 1:size(state_reward_2k,2)
    trialwise_EMG(iTrial).session = session;
    if strcmp('CO',task)
        trialwise_EMG(iTrial).trial_start = state_start_2k(iTrial);
        trialwise_EMG(iTrial).trial_end = state_reward_2k(iTrial);
        trialwise_EMG(iTrial).trial_num = iTrial;
    elseif strcmp('RTP',task)
        trial_start_times_temp = state_start_2k(state_start_2k<state_reward_2k(iTrial));
        trialwise_EMG(iTrial).trial_start = trial_start_times_temp(end);
        trialwise_EMG(iTrial).trial_end = state_reward_2k(iTrial);
        trialwise_EMG(iTrial).trial_num = find(state_start_2k == trialwise_EMG(iTrial).trial_start);
    end
    for iMuscle = 1:length(channels_to_analyze)
        trialwise_EMG(iTrial).(strcat('EMG_',muscle_labels{channels_to_analyze(iMuscle)}))...
            = final_lowpass_data(iMuscle,trialwise_EMG(iTrial).trial_start:trialwise_EMG(iTrial).trial_end);
    end
end
end