init;

samples = 1e3;

%% Load a platform and an application.
%
filename = Utils.resolvePath('004_080.tgff');
[ platform, application ] = System.parseTGFF(filename);

%% Construct a schedule.
%
schedule = System.Schedule.Dense(platform, application);
priority = schedule.priority;
mapping = schedule.mapping;
executionTime = schedule.executionTime;

tic;
for i = 1:samples
  %% Construct another schedule.
  %
  schedule = System.Schedule.Dense(platform, application, ...
    'priority', priority, 'mapping', mapping, 'executionTime', executionTime);
end
time = toc;

fprintf('Monte Carlo:\n');
fprintf('  Samples: %d\n', samples);
fprintf('  Simulation time: %.2f s\n', time);
