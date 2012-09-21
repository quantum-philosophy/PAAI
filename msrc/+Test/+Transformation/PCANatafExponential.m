init;

samples = 1e6;
dimension = 100;

%% Generate a correlation matrix.
%
C0 = Correlation.Pearson.random(dimension);

%% Define the marginal distributions.
%
distribution = ProbabilityDistribution.Exponential();

%% Construct a vector of correlated RVs.
%
rvsDependent = RandomVariables.Homogeneous(distribution, C0);

%% Transformation without reduction.
%
transformation = Transformation.Nataf();
transformation.perform(rvsDependent);
data = transformation.sample(samples);
C1 = Correlation.Pearson.compute(data);

%% Transformation with reduction.
%
transformation = Transformation.PCANataf();
transformation.perform(rvsDependent);
data = transformation.sample(samples);
C2 = Correlation.Pearson.compute(data);

fprintf('Initial dimensions: %d\n', dimension);
fprintf('Reduced dimensions: %d\n', transformation.reducedDimension);

fprintf('Infinity norm without reduction: %e\n', ...
  norm(C0.matrix - C1.matrix, Inf));
fprintf('Infinity norm with reduction:    %e\n', ...
  norm(C0.matrix - C2.matrix, Inf));
