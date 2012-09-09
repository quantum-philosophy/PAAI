function raw = evaluateSet(pc, coeffSet, rvs)
  [ ddim, terms, tdim ] = size(coeffSet);
  assert(ddim == pc.ddim, 'The deterministic dimension is invalid.');
  assert(terms == pc.terms, 'The number of terms is invalid.');

  mterms = size(pc.rvProd, 1);
  points = size(rvs, 2);

  rvPower = pc.rvPower;
  rvProd = zeros(mterms, points);

  for i = 1:mterms
    rvProd(i, :) = prod(realpow(rvs, irep(rvPower(:, i), 1, points)), 1);
  end

  raw = zeros(points, ddim, tdim);

  for i = 1:tdim
    raw(:, :, i) = transpose((coeffSet(:, :, i) * pc.coeffMap) * rvProd);
  end
end
