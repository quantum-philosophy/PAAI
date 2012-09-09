function [ Exp, Cov, Raw ] = sample(f, dims, samples)
  %
  % Description:
  %
  %   Performs `Nmcs' evaluations of the given function `f' and
  %   computes the corresponding expectation and covariance.
  %
  % Output:
  %
  %   * Exp - the expectation of `f',
  %   * Cov - the covariance matrix of `f',
  %   * Raw - the samples used to compute the stats.
  %

  if nargin < 3, Nmcs = 10000; end

  sdim = dims(1);
  ddim = dims(2);

  rvs = normrnd(0, 1, sdim, samples);
  Raw = zeros(ddim, samples);

  for i = 1:samples
    Raw(:, i) = f(rvs(:, i));
  end

  Raw = transpose(Raw);

  Exp = mean(Raw);
  Cov = cov(Raw);
end
