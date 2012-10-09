function [ schedule, parameters ] = constructBeta(platform, application, varargin)
  options = Options(varargin{:});

  %% Construct a schedule.
  %
  schedule = Schedule.Dense(platform, application);

  taskIndex = options.get('taskIndex', []);
  if isempty(taskIndex), taskIndex = 1:length(application); end

  alpha = options.get('alpha', 1);
  beta = options.get('beta', 3);
  deviation = options.get('deviation', 0.5);

  %% Determine the marginal distributions.
  %
  distributions = {};
  for time = schedule.executionTime(taskIndex)
    delta = deviation * time;
    distributions{end + 1} = ...
      ProbabilityDistribution.Beta( ...
        'alpha', alpha, 'beta', beta, 'a', -delta / 4, 'b', 3 * delta / 4);
  end

  switch length(taskIndex)
  case 1
    parameters = RandomVariables.Single(distributions{1});
  otherwise
    %% Generate a correlation matrix.
    %
    correlation = Correlation.Pearson.random(length(taskIndex));

    %% Construct a vector of correlated RVs.
    %
    parameters = RandomVariables.Heterogeneous(distributions, correlation);
  end
end
