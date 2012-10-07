function [ platform, application, schedule, parameters ] = constructBeta(name)
  %% Load a platform and an application.
  %
  filename = Utils.resolvePath([ name, '.tgff' ]);
  [ platform, application ] = System.parseTGFF(filename);

  %% Construct a schedule.
  %
  schedule = System.Schedule.Dense(platform, application);

  %% Determine the marginal distributions.
  %
  distributions = {};
  for time = schedule.executionTime
    distributions{end + 1} = ...
      ProbabilityDistribution.Beta( ...
        'alpha', 1, 'beta', 3, 'a', 0, 'b', 0.2 * time);
  end

  %% Generate a correlation matrix.
  %
  correlation = Correlation.Pearson.random(length(application));

  %% Construct a vector of correlated RVs.
  %
  parameters = RandomVariables.Heterogeneous(distributions, correlation);
end
