function [ nodes, weights ] = construct(this, options)
  dimension = options.dimension;
  order = options.level;

  pointSet = zeros(1, order);
  nodeSet = cell(order);
  weightSet = cell(order);

  %
  % Compute one-dimensional rules for all the needed levels.
  %
  for level = 1:order
    quadrature = Quadrature.(options.quadratureName)( ...
      'dimension', 1, 'level', level, 'method', 'tensor', ...
      options.get('quadratureOptions', Options()));

    pointSet(level) = length(quadrature.weights);
    nodeSet{level} = quadrature.nodes;
    weightSet{level} = quadrature.weights;
  end

  maxLevel = order - 1;
  minLevel = max(0, order - dimension);

  points = 0;
  nodes = [];
  weights = [];

  for level = minLevel:maxLevel
    coefficient = (-1)^(maxLevel - level) * ...
      nchoosek(dimension - 1, dimension + level - order);

    %
    % Compute all combinations that sum up to `level'.
    %
    indexSet = get_seq(dimension, dimension + level);

    newPoints = prod(pointSet(indexSet), 2);
    totalNewPoints = sum(newPoints);

    %
    % Preallocate space for new points.
    %
    nodes = [ nodes; zeros(totalNewPoints, dimension) ];
    weights = [ weights; zeros(totalNewPoints, 1) ];

    %
    % Append the new nodes and weights.
    %
    for i = 1:size(indexSet, 1)
      index = indexSet(i, :);

      [ newNodes, newWeights ] = ...
        tensor_product(nodeSet(index), weightSet(index));

      nodes((points + 1):(points + newPoints(i)), :) = newNodes;
      weights((points + 1):(points + newPoints(i))) = coefficient * newWeights;

      points = points + newPoints(i);
    end

    %
    % Sort the nodes.
    %
    [ nodes, I ] = sortrows(nodes);
    weights = weights(I);

    %
    % Merge repeated values.
    %
    keep = [ 1 ];
    last = 1;

    for i = 2:size(nodes, 1)
      if nodes(i, :) == nodes(i - 1, :)
        weights(last) = weights(last) + weights(i);
      else
        last = i;
        keep = [ keep; i ];
      end
    end

    nodes = nodes(keep, :);
    weights = weights(keep);
  end

  %
  % Normalize the weights.
  %
  weights = weights / sum(weights);
end
