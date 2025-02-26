% Cross-subject kinematic comparison
% [~, colors] = colornames('xkcd', ...
%     'black','grey','red','brown','purple','blue','hot pink','orange', ...
%     'mustard','green','teal','light blue','olive green', ...
%     'peach','periwinkle','magenta','salmon','lime green');
%% 
bx_data = load('C:\Users\Caleb (Work)\Documents\git\intermittent_control_project\data\python_switching_models\BxRTP0.05sBins\BxRTP190228CT0.mat');
rs_data = load('C:\Users\Caleb (Work)\Documents\git\intermittent_control_project\data\python_switching_models\RSRTP0.05sBins\RS_RTP.mat');
rj_data = load('C:\Users\Caleb (Work)\Documents\git\intermittent_control_project\data\python_switching_models\RJRTP0.05sBins\RJRTP.mat');

%%
rs_x_position = vertcat(rs_data.data.x_smoothed);
rj_x_position = vertcat(rj_data.data.x_smoothed);
bx_x_position = [bx_data.data.x_smoothed]';

rs_y_position = vertcat(rs_data.data.y_smoothed);
rj_y_position = vertcat(rj_data.data.y_smoothed);
bx_y_position = [bx_data.data.y_smoothed]';

% rs_position_normalized = normalize([rs_x_position,rs_y_position],'range');
% rj_position_normalized = normalize([rj_x_position,rj_y_position],'range');
% bx_position_normalized = normalize([bx_x_position,bx_y_position],'range');
% 
% % [~,rs_radius,~] = curvature(rs_position_normalized);
% % [~,rj_radius,~] = curvature(rj_position_normalized);
% % [~,bx_radius,~] = curvature(bx_position_normalized);
% 
% rs_speed = sqrt((diff(rs_position_normalized(:,1)).^2) + (diff(rs_position_normalized(:,2)).^2));
% rj_speed = sqrt((diff(rj_position_normalized(:,1)).^2) + (diff(rj_position_normalized(:,2)).^2));
% bx_speed = sqrt((diff(bx_position_normalized(:,1)).^2) + (diff(bx_position_normalized(:,2)).^2));
% 
% rs_acceleration = diff(rs_speed);
% rj_acceleration = diff(rj_speed);
% bx_acceleration = diff(bx_speed);
%%
rs_speed = vertcat(rs_data.data.speed);
rj_speed = vertcat(rj_data.data.speed);
bx_speed = [bx_data.data.speed]';

rs_acceleration = vertcat(rs_data.data.acceleration);
rj_acceleration = vertcat(rj_data.data.acceleration);
bx_acceleration = [bx_data.data.acceleration]';

%%
rs_acceleration_maxima = findpeaks(rs_speed);
rj_acceleration_maxima = findpeaks(rj_speed);
bx_acceleration_maxima = findpeaks(bx_speed);
rs_acceleration_minima = findpeaks(-rs_speed);
rj_acceleration_minima = findpeaks(-rj_speed);
bx_acceleration_minima = findpeaks(-bx_speed);


%% Video Time
xlims = [min([bx_data.data.x_smoothed]) max([bx_data.data.x_smoothed])];
ylims = [min([bx_data.data.y_smoothed]) max([bx_data.data.y_smoothed])];

v = VideoWriter('C:\Users\calebsponheim\Documents\git\intermittent_control_project\figures\Bx\RTP_CT0\kinematics.mp4','MPEG-4');
v.Quality = 50;
v.FrameRate = 30;
open(v)

for iTrial = 10
    for iFrame = 1:50:(size(bx_data.data(iTrial).x_smoothed,2)-50)
        figure('visible','off');hold on
        plot(bx_data.data(iTrial).x_smoothed(iFrame:iFrame+50),bx_data.data(iTrial).y_smoothed(iFrame:iFrame+50));
        xlim(xlims)
        ylim(ylims)
        frame = getframe(gcf);
        writeVideo(v,frame)
    end
    disp(strcat('trial',num2str(iTrial),' done'))
end
close(v)
%%
% x1 = -bx_acceleration_minima;
% x2 = -rj_acceleration_minima;
% x3 = -rs_acceleration_minima;

% x1 = bx_acceleration_maxima;
% x2 = rj_acceleration_maxima;
% x3 = rs_acceleration_maxima;

% x1 = bx_radius(~isnan(rs_radius));
% x2 = rj_radius(~isnan(rj_radius));
% x3 = rs_radius(~isnan(rs_radius));


% x1 = bx_position_normalized(:,2);
% x2 = rj_position_normalized(:,2);
% x3 = rs_position_normalized(:,2);
% 
x1 = bx_speed;
x2 = rj_speed;
x3 = rs_speed;
x = [x1; x2; x3];

g1 = repmat({'Bx'},length(x1),1);
g2 = repmat({'Rj'},length(x2),1);
g3 = repmat({'Rs'},length(x3),1);
g = [g1; g2; g3];

figure('visible','on'); hold on
boxplot(x,g)


% [~, ~, ~, q_temp, ~] = al_goodplot(bx_speed(1:5:end),1,0.75, colors(1,:), 'right', .1,std(bx_speed(1:5:end))/1000,1);
% q(1) = q_temp(7,1);
% [~, ~, ~, q_temp, ~] = al_goodplot(rs_speed(1:5:end),2,0.75, colors(2,:), 'right', .1,std(rs_speed(1:5:end))/1000,1);
% q(2) = q_temp(7,1);
% [~, ~, ~, q_temp, ~] = al_goodplot(rj_speed(1:5:end),3,0.75, colors(3,:), 'right', .1,std(rj_speed(1:5:end))/1000,1);
% q(3) = q_temp(7,1);
% 
ylim([min(x) max(x)])
% xticklabels({'Bx','RS','RJ'})
hold off
box off
% set(gcf,'color','w','Position',[100 100 600 800])
% title(strcat('subject comparison for speed'));
% xlabel('State Number')
% ylabel('speed')
%%
edges = [-.015 : .0005 : .015];

figure; hold on; 
histogram(rs_acceleration,edges,'DisplayName','RS'); 
histogram(rj_acceleration,edges,'DisplayName','RJ')
histogram(bx_acceleration,edges,'DisplayName','BX')
title('acceleration values across all kinematics')
legend()
xlim([-.015 .015])
%%


saveas(gcf,strcat('C:\Users\calebsponheim\Documents\git\intermittent_control_project\figures\cross-subject_speed.png'));
close gcf