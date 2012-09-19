function correlation = computeCorrelation(this, rvs)
  dimension = rvs.dimension;

  qd = Quadrature.GaussHermite( ...
    'dimension', 2, ...
    'level', this.quadratureLevel, ...
    'method', 'tensor');

  nodes = qd.nodes;
  weights = qd.weights;

  correlation = diag(ones(1, dimension));

  for i = 1:dimension
    for j = (i + 1):dimension
      rho0 = rvs.correlation.matrix(i, j);

      goal = @(rho) rho0 - sum(weights .* nodes(1, :) .* ...
        (rho * nodes(1, :) + sqrt(1 - rho^2) * nodes(2, :)));

      correlation(i, j) = fminbnd(goal, -1, 1);
      correlation(j, i) = correlation(i, j);
    end
  end

  correlation = Correlation.Pearson(correlation);
end
