function [meta, snippet_data] = postmodel_analysis(meta,data)

if strcmp(getenv('USERNAME'),'calebsponheim')
    file_base_base = 'C:\Users\calebsponheim';
elseif strcmp(getenv('USERNAME'),'caleb_work')
     file_base_base = 'C:\Users\Caleb (Work)';
end
    
[~, colors] = colornames('xkcd', ...
    'black','grey','red','brown','purple','blue','hot pink','orange', ...
    'mustard','green','teal','light blue','olive green', ...
    'peach','periwinkle','magenta','salmon','lime green','black','grey','red','brown','purple');

% Create Plot Figure Results Folder
if meta.crosstrain == 0 
    if meta.move_only == 1
        meta.figure_folder_filepath = strcat(file_base_base,'\Documents\git\intermittent_control_project\figures\',meta.subject,'\',meta.task,'_CT0_move_only\');
    elseif contains(meta.session,'180323')
        meta.figure_folder_filepath = strcat(file_base_base,'\Documents\git\intermittent_control_project\figures\',meta.subject,'\',meta.task,'18_CT0\');
    else
        meta.figure_folder_filepath = strcat(file_base_base,'\Documents\git\intermittent_control_project\figures\',meta.subject,'\',meta.task,'_CT0\');
    end
else
    meta.figure_folder_filepath = strcat(file_base_base,'\Documents\git\intermittent_control_project\figures\',meta.subject,'\CT',meta.task,'\');
end

if meta.use_rslds == 1
    meta.figure_folder_filepath = strcat(meta.figure_folder_filepath,'rslds\');
    meta.figure_folder_filepath = strcat(meta.figure_folder_filepath,num2str(meta.optimal_number_of_states),"_states_",num2str(meta.num_dims),"_dims\");
elseif meta.use_rslds == 0
    meta.figure_folder_filepath = strcat(meta.figure_folder_filepath,'hmm\',num2str(meta.optimal_number_of_states),"_states\");
end

% Create Snippet Timing

% Segment Analysis
[meta,data,snippet_data,sorted_state_transitions] = segment_analysis_v2(meta,data);

%% Plot Everything
meta = plot_state_normalized_velocity(meta,data,snippet_data,colors);

% Plot Single Trials
plot_single_trials_v2(meta,data,colors)
% Plot Segments
plot_state_snippets(meta,data,snippet_data,colors)
% Plot State Direction
snippet_direction_out = plot_state_direction(meta,data,snippet_data,colors);

% Plot all Trials
% plot_all_trials_v2(meta,data,colors);

% Plot num extrema versus num transitions
plot_extrema_vs_transitions(meta,data)

% Plot normalized velocity

% Plot Mean Snippet Lengths

snippet_length_per_state = plot_state_lengths(meta,snippet_data,colors);

% Plot Curvature Metrics for States

meta = plot_curvature(meta,data,snippet_data,colors,file_base_base);

% Compare Extrema Timing to Transition Timing

extrema_vs_transition_timing(data,meta)

if meta.plot_ll_rslds == 1
    plot_rslds_ll(data,meta)
end
if meta.use_rslds == 1
    eig_angles(meta,sorted_state_transitions)
    plot_eigs(meta,colors,snippet_direction_out,snippet_length_per_state)  
end

% if contains(meta.task,'CO')
%     plot_continuous_states(meta,data)
% end 
end