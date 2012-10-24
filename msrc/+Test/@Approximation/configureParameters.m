function configureParameters(this)
  this.inputDimension = length(this.taskIndex);

  %
  % Determine the marginal distributions.
  %
  distributions = {};
  for executionTime = this.schedule.executionTime(this.taskIndex)
    deviation = 0.2 * executionTime;
    distributions{end + 1} = ProbabilityDistribution.Beta( ...
        'alpha', 1, 'beta', 1, 'a', 0, 'b', deviation);
  end

  switch this.inputDimension
  case 1
    this.parameters = RandomVariables.Single(distributions{1});
  otherwise
    %
    % Generate a correlation matrix.
    %
    if this.independent
      correlation = eye(this.inputDimension);
    else
      correlation = Utils.generateCorrelation(this.inputDimension);
    end

    %
    % Construct a vector of correlated RVs.
    %
    this.parameters = RandomVariables.Heterogeneous( ...
      distributions, correlation);
  end

  %
  % Perform the probability transformation.
  %
  switch this.method
  case 'PC'
    this.transformation = ProbabilityTransformation.Normal(this.parameters);
  otherwise
    this.transformation = ProbabilityTransformation.Uniform(this.parameters);
  end
end
