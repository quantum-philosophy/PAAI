init;

%% Load a platform and an application.
%
filename = Utils.resolvePath('004_080.tgff');
[ platform, application ] = System.parseTGFF(filename)

%% Construct a schedule.
%
schedule = System.Schedule.Dense(platform, application)

%% Draw.
%
schedule.draw()
