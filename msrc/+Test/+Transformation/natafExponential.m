init;

samples = 1e5;
dimension = 2;

%% Generate a correlation matrix.
%
correlation = Correlation.Pearson.random(dimension);
fprintf('Desired correlation matrix:\n');
correlation

%% Define the marginal distributions.
%
distributions = {};
for i = 1:dimension
  distributions{end + 1} = ProbabilityDistribution.Exponential();
end

%% Construct a vector of correlated RVs.
%
rvsDependent = RandomVariables.Heterogeneous( ...
  dimension, distributions, correlation);

%% Transform the dependent RVs into independent ones.
%
transformation = Transformation.Nataf(rvsDependent);

%% Sample the transformed RVs.
%
data = transformation.sample(samples);

%% Draw the result.
%
Stats.observe(data, 'method', 'histogram', 'draw', true);
