init;

dimension = 5;
level = 5;

grid = SparseGrid.Smolyak( ...
  'dimension', dimension, 'level', level, ...
  'quadratureName', 'GaussHermite');

[ nodes, weights ] = nwspgr('gqn', dimension, level);
points = length(weights);

fprintf('Expected points: %d\n', points);
fprintf('Computed points: %d\n', grid.points);

fprintf('Infinity norm of nodes: %e\n', ...
  norm(nodes - grid.nodes, Inf));
fprintf('Infinity norm of weights: %e\n', ...
  norm(weights - grid.weights, Inf));
