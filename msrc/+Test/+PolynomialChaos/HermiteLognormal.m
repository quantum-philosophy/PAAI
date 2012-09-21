init;

samples = 1e4;

%% Choose a distribution.
%
distribution = ProbabilityDistribution.Lognormal( ...
  'normalMu', 0, 'normalSigma', 0.7);
variables = RandomVariables.Single(distribution);

%% Perform the transformation.
%
transformation = Transformation.Single();
transformation.perform(variables);

%% Construct the PC expansion.
%
quadratureOptions = Options('level', 10);
chaos = PolynomialChaos.Hermite('order', 5, ...
  'quadratureName', 'GaussHermite', ...
  'quadratureOptions', quadratureOptions);

%% Sample the expansion.
%
[ pcExp, pcVar, pcData ] = chaos.sample(@transformation.evaluate, samples);

%% Compare.
%
mcData = distribution.sample(samples, 1);

exp = distribution.mu;
var = distribution.sigma^2;

fprintf('Error of expectation: %.2f %%\n', ...
  100 * (exp - pcExp) / exp);
fprintf('Error of variance: %.2f %%\n', ...
  100 * (var - pcVar) / var);

Stats.compare(mcData, pcData, ...
  'draw', true, 'method', 'histogram', 'range', 'unbounded');
