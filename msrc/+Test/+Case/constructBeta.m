function [ platform, application, schedule, parameters ] = ...
  constructBeta(name, taskIndex)

  %% Load a platform and an application.
  %
  filename = Utils.resolvePath([ name, '.tgff' ]);
  [ platform, application ] = parseTGFF(filename);

  %% Construct a schedule.
  %
  schedule = Schedule.Dense(platform, application);

  if nargin < 2, taskIndex = 1:length(application); end

  %% Determine the marginal distributions.
  %
  distributions = {};
  for time = schedule.executionTime(taskIndex)
    distributions{end + 1} = ...
      ProbabilityDistribution.Beta( ...
        'alpha', 1, 'beta', 3, 'a', 0, 'b', 0.5 * time);
  end

  switch length(taskIndex)
  case 1
    parameters = RandomVariables.Single(distributions{1});
  otherwise
    %% Generate a correlation matrix.
    %
    correlation = Correlation.Pearson.random(dimensionCount);

    %% Construct a vector of correlated RVs.
    %
    parameters = RandomVariables.Heterogeneous(distributions, correlation);
  end
end
