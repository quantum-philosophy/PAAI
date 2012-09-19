function correlation = computeCorrelation(this, rvs)
  dimension = rvs.dimension;

  qd = Quadrature.GaussHermite(this.quadratureOptions);
  nodes = qd.nodes;
  weights = qd.weights;

  normal = this.normal;

  matrix = diag(ones(1, dimension));

  for i = 1:dimension
    for j = (i + 1):dimension
      rv1 = rvs{i};
      rv2 = rvs{j};

      mu1 = rv1.mu;
      mu2 = rv2.mu;

      sigma1 = rv1.sigma;
      sigma2 = rv2.sigma;

      rho0 = rvs.correlation(i, j);

      weightsOne = weights .* (rv1.invert(normal.apply(nodes(1, :))) - mu1);
      two = @(rho) rv2.invert(normal.apply(rho * nodes(1, :) + sqrt(1 - rho^2) * nodes(2, :))) - mu2;
      goal = @(rho) abs(rho0 - sum(weightsOne .* two(rho)) / sigma1 / sigma2);

      [ matrix(i, j), ~, ~, out ] = fminbnd(goal, -0.9, 0.9, this.optimizationOptions);

      matrix(j, i) = matrix(i, j);
    end
  end

  correlation = Correlation.Pearson(matrix);
end

function rho = echo(rho)
  rho
end
