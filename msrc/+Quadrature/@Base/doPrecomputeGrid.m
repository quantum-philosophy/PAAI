function [ nodes, grid, norm ] = doPrecomputeGrid(qd, x, psi, index, method)
  sdim = length(x);
  terms = length(psi);

  order = method.quadratureOrder;
  level = method.quadratureLevel;
  type = lower(method.quadratureType);

  pointsTP = qd.countTensorProductPoints(sdim, order);
  pointsSG = qd.countSparseGridPoints(sdim, order, level);

  Utils.debug( ...
    { 'Precomputation of a new grid.' }, ...
    { '  Method: %s', Quadrature.methodName(method) }, ...
    { '  Stochastic dimensions: %d', sdim }, ...
    { '  Tensor product points: %d', pointsTP }, ...
    { '  Sparse grid points: %d', pointsSG });

  if strcmp(type, 'adaptive')
    if pointsTP <= pointsSG
      type = 'tensor';
    else
      type = 'sparse';
    end
  end

  switch type
  case 'tensor'
    [ nodes, weights, points ] = qd.constructTensorProduct(sdim, order);
    assert(points == pointsTP, 'The number of points is invalid.');
  case 'sparse'
    [ nodes, weights, points ] = qd.constructSparseGrid(sdim, order, level);
    assert(points == pointsSG, 'The number of points is invalid.');
  otherwise
    error('The method type is unknown.');
  end

  grid = zeros(terms, points);

  norm = zeros(1, terms);

  for i = 1:terms
    f = Utils.toFunction(psi(i), x, 'rows');
    norm(i) = qd.computeNormalizationConstant(i, index);
    grid(i, :) = f(nodes) .* weights / norm(i);
  end

  [ nodes, grid, norm ] = qd.finalize(sdim, nodes, grid, norm);

  assert(all(norm >= 0), 'Normalization constants cannot be negative.');
end
