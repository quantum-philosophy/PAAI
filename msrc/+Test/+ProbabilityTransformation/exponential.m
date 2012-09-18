init;

samples = 1e5;
dimension = 2;

%% Generate correlations.
%
correlation = Correlation.Spearman(dimension);
fprintf('Desired ');
correlation

distributions = {};

for i = 1:dimension
  distributions{end + 1} = ProbabilityDistribution.Exponential();
end

parameters = UncertainParameters.Heterogeneous(distributions, correlation);
transformation = ProbabilityTransformation.Uniform(parameters);

originalData = parameters.sample(samples);
correlation = Correlation.Spearman(dimension, originalData);
fprintf('Original ');
correlation

transformedData = transformation.sample(samples);
correlation = Correlation.Spearman(dimension, transformedData);
fprintf('Transformed ');
correlation

Stats.compare(originalData, transformedData, ...
  'method', 'histogram', 'draw', true);
