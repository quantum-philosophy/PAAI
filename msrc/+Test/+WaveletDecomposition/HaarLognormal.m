function HaarLognormal
  setup;

  samples = 1e4;

  %% Choose a distribution.
  %
  distribution = ProbabilityDistribution.Lognormal( ...
    'normalMu', 0, 'normalSigma', 0.7);
  variables = RandomVariables.Single(distribution);

  %% Perform the transformation.
  %
  transformation = Transformation.SingleNormal(variables);

  f = @transformation.evaluate;
  % f = @(x) (-0.2 <= x) .* (x < 0.5);

  %% Sample the expansion.
  %
  [ smExp, smVar, smData ] = sample(f, samples, 10);

  %% Compare.
  %
  mcData = f(normrnd(0, 1, samples, 1));
  mcExp = mean(mcData);
  mcVar = var(mcData);

  fprintf('Error of expectation: %.2f %%\n', ...
    100 * (mcExp - smExp) / mcExp);
  fprintf('Error of variance: %.2f %%\n', ...
    100 * (mcVar - smVar) / mcVar);

  Stats.compare(mcData, smData, ...
    'draw', true, 'method', 'histogram', 'range', 'unbounded');
end

function [ Exp, Var, Data ] = sample(f, samples, resolution)
  terms = 2^resolution;
  [ J, K ] = waveletIndex(terms - 1);

  coeff = zeros(terms, 1);
  coeff(1) = integrate(@(u) f(norminv(u)));
  for i = 2:terms
    coeff(i) = integrate(@(u) f(norminv(u)) .* wavelet(u, J(i - 1), K(i - 1)));
  end

  Exp = coeff(1);
  Var = sum(coeff(2:end) .^ 2);

  z = normrnd(0, 1, samples, 1);
  u = normcdf(z);

  Values = zeros(samples, terms);
  Values(:, 1) = 1;
  for i = 2:terms
    Values(:, i) = wavelet(u, J(i - 1), K(i - 1));
  end

  Data = Values * coeff;
end

function result = integrate(f)
  result = quadgk(f, 0, 1 - 1e-8);
end

function result = wavelet(u, j, k)
  result = 2^(j / 2) * motherWavelet(2^j * u - k);
end

function result = motherWavelet(u)
  result = (0 <= u) .* (u < 0.5) - (0.5 <= u) .* (u < 1);
end

function [ J, K ] = waveletIndex(count)
  J = zeros(1, count);
  K = zeros(1, count);

  j = 0;
  k = 0;
  for i = 1:count
    J(i) = j;
    K(i) = k;

    k = k + 1;
    if k > (2^j - 1)
      k = 0;
      j = j + 1;
    end
  end
end
