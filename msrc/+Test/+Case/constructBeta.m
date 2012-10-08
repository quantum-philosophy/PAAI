function [ platform, application, schedule, parameters ] = constructBeta(name, dimension)
  %% Load a platform and an application.
  %
  filename = Utils.resolvePath([ name, '.tgff' ]);
  [ platform, application ] = System.parseTGFF(filename);

  %% Construct a schedule.
  %
  schedule = System.Schedule.Dense(platform, application);

  if nargin < 2, dimension = length(schedule); end

  %% Determine the marginal distributions.
  %
  distributions = {};
  for time = schedule.executionTime(1:dimension)
    distributions{end + 1} = ...
      ProbabilityDistribution.Beta( ...
        'alpha', 1, 'beta', 3, 'a', 0, 'b', 0.2 * time);
  end

  switch dimension
  case 1
    parameters = RandomVariables.Single(distributions{1});
  otherwise
    %% Generate a correlation matrix.
    %
    correlation = Correlation.Pearson.random(dimension);

    %% Construct a vector of correlated RVs.
    %
    parameters = RandomVariables.Heterogeneous(distributions, correlation);
  end
end
