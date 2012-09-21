init;

samples = 1e3;

%% Load a platform and an application.
%
filename = Utils.resolvePath('002_020.tgff');
[ platform, application ] = System.parseTGFF(filename);

%% Construct a schedule.
%
schedule = System.Schedule.Dense(platform, application);
priority = schedule.priority;
mapping = schedule.mapping;
executionTime = schedule.executionTime;

%% Determine the marginal distributions.
%
distributions = {};
for time = executionTime
  distributions{end + 1} = ...
    ProbabilityDistribution.Beta( ...
      'alpha', 1, 'beta', 3, 'a', 0, 'b', 0.2 * time);
end

%% Determine the correlation matrix.
%
correlation = Correlation.Pearson.random(length(application));

%% Construct a vector of correlated RVs.
%
parameters = RandomVariables.Heterogeneous(distributions, correlation);

%% Perform the Nataf transformation.
%
transformation = Transformation.Nataf();
transformation.perform(parameters);

startTime = zeros(samples, length(application));

tic;
for i = 1:samples
  %% Construct another schedule.
  %
  schedule = System.Schedule.Dense(platform, application, ...
    'priority', priority, 'mapping', mapping, ...
    'executionTime', executionTime + transformation.sample(1));

  startTime(i, :) = schedule.startTime;
end
time = toc;

fprintf('Monte Carlo:\n');
fprintf('  Samples: %d\n', samples);
fprintf('  Simulation time: %.2f s\n', time);

for i = 2:10
  Stats.observe(startTime(:, i), ...
    'draw', 'true', 'method', 'histogram', 'range', 'unbounded');
end
