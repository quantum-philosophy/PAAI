setup;

%% Load a platform and an application.
%
filename = Utils.resolvePath('002_020.tgff');
[ platform, application ] = System.parseTGFF(filename)

%% Construct a schedule.
%
schedule = System.Schedule.Dense(platform, application)

%% Draw.
%
schedule.draw()

fprintf('Duration: %.4f s\n', duration(schedule));
