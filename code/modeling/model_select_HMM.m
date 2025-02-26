function [meta] = model_select_HMM(data,meta)
%% MODEL SELECT HMM

% Get list of files in data_midway/hn-trained
% filter list by crosstrain type (so, pull in meta)
file_list = dir('.\data_midway\hn_trained');
folder = file_list(1).folder;
file_list = {file_list.name};

dataset_to_evaluate = 'train';

if (meta.crosstrain == 0) || (meta.crosstrain == 3) % 0: none || 3: both tasks together
    model_files = cellfun(@(x)[folder '\' x],file_list(...
        endsWith(file_list,['CT' num2str(meta.crosstrain) '.mat'])),'UniformOutput',false);
    
    model_files = model_files(contains(model_files,[meta.subject meta.task]));
elseif meta.crosstrain == 1 %1: RTP model, center-out decode
    model_files = cellfun(@(x)[folder '\' x],file_list(endsWith(file_list,'CT0.mat')),'UniformOutput',false);
    model_files = model_files(contains(model_files,[meta.subject 'RTP']));
elseif meta.crosstrain == 2 %2: Center-out model, RTP decode
    model_files = cellfun(@(x)[folder '\' x],file_list(endsWith(file_list,'CT0.mat')),'UniformOutput',false);
    model_files = model_files(contains(model_files,[meta.subject 'center_out']));
end

state_num_range = 2:(numel(model_files)+1);
% load the correct CT data file

trInd_model_select = cellfun(@(x) strcmp(x,'model_select'),[data.trial_classification]);
trInd_train = cellfun(@(x) strcmp(x,'train'),[data.trial_classification]);
trInd_test = cellfun(@(x) strcmp(x,'test'),[data.trial_classification]);

for iStateNum = state_num_range % for each state num
    if sum(endsWith(model_files,['_' num2str(iStateNum) '_states_CT0.mat'])) > 0
        hn_trained_temp = load(model_files{endsWith(model_files,['_' num2str(iStateNum) '_states_CT0.mat'])},'hn_trained'); % load their models
        hn_trained_temp = hn_trained_temp.hn_trained;
        num_states_temp = size(hn_trained_temp{1}.a,1);
        num_params(num_states_temp-1) = (iStateNum * (iStateNum-1));% + numel(hn_trained_temp{1, 1}.prior) + numel(hn_trained_temp{1, 1}.b(2:end,:,:));
        num_states_for_plotting(num_states_temp-1) = num_states_temp;
        % decode ALL trials
        for iIter = 1:numel(hn_trained_temp)
            dc_temp = decode_trials(hn_trained_temp{iIter},data,meta);
            dc_temp_ll = [dc_temp.ll];
            dc_temp_ll_model_select(num_states_temp-1,iIter,:) = dc_temp_ll(trInd_model_select);
            dc_temp_ll_train(num_states_temp-1,iIter,:) = dc_temp_ll(trInd_train);
            dc_temp_ll_test(num_states_temp-1,iIter,:) = dc_temp_ll(trInd_test);
        end
        % label each dc trial by group (from array_data)
        % if the trial is "model select", then pull those trials aside alongside their state num
        disp(['processed models for ' num2str(num_states_temp) ' states'])
    else
        disp("we're missing something");
    end
end
ll_mean_model_select = mean(dc_temp_ll_model_select,3);
ll_mean_train = mean(dc_temp_ll_train,3);
ll_mean_test = mean(dc_temp_ll_test,3);
%%
if strcmp(dataset_to_evaluate,'train')
    LL = ll_mean_train;
elseif strcmp(dataset_to_evaluate,'test')
    LL = ll_mean_test;
elseif strcmp(dataset_to_evaluate,'model_select')
    LL = ll_mean_model_select;
end
k = num_params;
AIC = [];
AIC_state_nums = [];
for iIter = 1:size(LL,2)
    AIC = [AIC,(((-2)*(LL(:,iIter))) + (2 * (k')))'];
    AIC_state_nums = [AIC_state_nums,num_states_for_plotting];
end

% Get rid of zeros
AIC = AIC(AIC ~= 0);
AIC_state_nums = AIC_state_nums(AIC_state_nums ~= 0);

% get rid of weird matlab dropouts
AIC_plot = AIC(AIC > mean(AIC)/2);
AIC_state_nums = AIC_state_nums(AIC > mean(AIC)/2);

%%
testfit = fit(AIC_state_nums',AIC_plot','poly2');

% taking average
for iState = unique(AIC_state_nums)
    AIC_mean(iState) = mean(AIC_plot(AIC_state_nums == iState));
    AIC_mean_state_num(iState) = iState;
end
AIC_mean = AIC_mean(AIC_mean ~= 0);
AIC_mean_state_num = AIC_mean_state_num(AIC_mean_state_num ~= 0);

% best_num_states = find(feval(testfit,1:max(AIC_state_nums)) == min(feval(testfit,1:max(AIC_state_nums))));
best_num_states = AIC_mean_state_num(AIC_mean == min(AIC_mean));
%% Plotting
% plot all the "model-select" trials dc ll together
figure('color','white','visible','off'); hold on
plot(AIC_state_nums,AIC_plot,'k.')
plot(AIC_mean_state_num,AIC_mean,'r-')
plot(best_num_states,min(AIC_mean),'ro','DisplayName','Optimal State Number');
xlabel('State Number')
ylabel('AIC')


%% saving this to meta params
meta.optimal_number_of_states = best_num_states;
%% Saving
if startsWith(matlab.desktop.editor.getActiveFilename,'C:\Users\calebsponheim\Documents\')
    saveas(gcf,['C:\Users\calebsponheim\Documents\git\intermittent_control_project\code\modeling\ll_plots\' meta.subject ' ' meta.task ' CT' num2str(meta.crosstrain) dataset_to_evaluate ' AIC.png']);
else
    saveas(gcf,[meta.subject ' ' meta.task ' CT' num2str(meta.crosstrain) dataset_to_evaluate ' AIC.png']');
end

close(gcf);

%% Plotting

LL_for_plotting = LL(LL < mean(LL)/2);
LL_state_nums = repmat(num_states_for_plotting',size(LL,2));
LL_state_nums = LL_state_nums(:,1);
LL_state_nums = LL_state_nums(LL < mean(LL)/2);


figure('color','white','visible','off'); hold on
plot(LL_state_nums,LL_for_plotting,'k.')
xlabel('State Number')
ylabel('Log Likelihood')


if startsWith(matlab.desktop.editor.getActiveFilename,'C:\Users\calebsponheim\Documents\')
    saveas(gcf,['C:\Users\calebsponheim\Documents\git\intermittent_control_project\code\modeling\ll_plots\' meta.subject ' ' meta.task ' CT' num2str(meta.crosstrain) dataset_to_evaluate ' LL.png']);
else
    saveas(gcf,[meta.subject ' ' meta.task ' CT' num2str(meta.crosstrain) dataset_to_evaluate ' LL.png']');
end

close(gcf);


figure('color','white','visible','off'); hold on
plot(state_num_range,num_params,'k.')
xlabel('State Number')
ylabel('Number of Parameters')

if startsWith(matlab.desktop.editor.getActiveFilename,'C:\Users\calebsponheim\Documents\')
    saveas(gcf,['C:\Users\calebsponheim\Documents\git\intermittent_control_project\code\modeling\ll_plots\' meta.subject ' ' meta.task ' CT' num2str(meta.crosstrain) dataset_to_evaluate ' params.png']);
else
    saveas(gcf,[meta.subject ' ' meta.task ' CT' num2str(meta.crosstrain) dataset_to_evaluate ' params.png']');
end

close(gcf);

end