function [ Exp, Var, Raw ] = sample(pc, f, samples)
  %
  % Output:
  %
  %   * Exp - the expectation of `f',
  %   * Var - the variance of `f',
  %   * Raw - a bunch of samples.
  %
  %   NOTE: `Raw' is not used to compute the expectation and variance.
  %

  if nargin < 3, samples = 10000; end

  ddim = pc.ddim;

  %
  % Obtain the coefficients.
  %
  coeff = pc.computeExpansion(f);

  %
  % Straight-forward stats.
  %
  Exp = coeff(:, 1);
  Var = diag(sum(coeff(:, 2:end).^2 .* Utils.replicate(pc.norm(2:end), ddim, 1), 2));

  %
  % Now sampling.
  %
  Raw = transpose(pc.evaluate(coeff, pc.generateSampleNodes(samples)));
end
