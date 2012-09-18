init;

samples = 1e5;
dimension = 2;

correlation = Correlation.Spearman(dimension);
distributions = {};

for i = 1:dimension
  distributions{end + 1} = ProbabilityDistribution.Exponential();
end

parameters = UncertainParameters.Heterogeneous(distributions, correlation);
transformation = ProbabilityTransformation.Uniform(parameters);

originalData = parameters.sample(samples);
transformedData = transformation.sample(samples);

Stats.compare(originalData, transformedData, 'draw', true);
