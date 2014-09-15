function configureParameters(this)
  this.inputCount = length(this.taskIndex);

  %
  % Determine the marginal distributions.
  %
  distributions = {};
  for executionTime = this.schedule.executionTime(this.taskIndex)
    deviation = 0.2 * executionTime;
    distributions{end + 1} = ProbabilityDistribution.Beta( ...
        'alpha', 1, 'beta', 1, 'a', 0, 'b', deviation);
  end

  %
  % Generate a correlation matrix.
  %
  if this.independent
    correlation = eye(this.inputCount);
  else
    correlation = Utils.generateCorrelation(this.inputCount);
  end

  %
  % Construct a vector of correlated RVs.
  %
  this.parameters = RandomVariables( ...
    'distributions', distributions, 'correlation', correlation);

  %
  % Perform the probability transformation.
  %
  switch this.method
  case 'PC'
    this.transformation = ProbabilityTransformation.Gaussian( ...
      'variables', this.parameters);
  otherwise
    this.transformation = ProbabilityTransformation.Uniform( ...
      'variables', this.parameters);
  end
end
