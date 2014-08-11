function construct(this, f, options)
  zeros = @uninit;

  inputCount  = uint32(options.inputCount);
  outputCount = uint32(options.outputCount);
  agentCount  = uint32(options.agentCount);

  samplingInterval = options.samplingInterval;

  adaptivityControl = options.get( ...
    'adaptivityControl', 'InfNormSurpluses');

  tolerance = options.get('tolerance', 1e-3);

  minimalLevel = options.get('minimalLevel', 2);
  maximalLevel = options.get('maximalLevel', 10);

  timeRange = 1:(2 * agentCount);
  dataRange = (2 * agentCount + 1):outputCount;

  %
  % NOTE: We convert strings to numbers due to a possible speedup later on.
  %
  switch adaptivityControl
  case 'InfNorm'
    adaptivityControl = uint8(0);
  case 'InfNormSurpluses'
    adaptivityControl = uint8(1);
  case 'InfNormSurpluses2'
    adaptivityControl = uint8(2);
  otherwise
    error('The specified adaptivity control method is unknown.');
  end

  verbose = @(varargin) [];
  if options.get('verbose', false)
    verbose = @(varargin) fprintf(varargin{:});
  end

  bufferSize = 200 * inputCount;
  stepBufferSize = 100 * 2 * inputCount;

  %
  % Preallocate some memory such that we do not need to reallocate
  % it at low levels. For high levels, the memory is reallocated
  % each time; however, since going from one high level to the
  % next one does not happen too often, we do not lose too much
  % of speed.
  %
  levelIndex    = zeros(bufferSize, inputCount, 'uint8');
  startIndex    = zeros(bufferSize, agentCount, 'uint32');
  finishIndex   = zeros(bufferSize, agentCount, 'uint32');
  nodes         = zeros(bufferSize, inputCount);
  values        = zeros(bufferSize, outputCount);
  surpluses     = zeros(bufferSize, outputCount);
  surpluses2    = zeros(bufferSize, outputCount);

  oldOrderIndex = zeros(stepBufferSize, inputCount, 'uint32');
  newLevelIndex = zeros(stepBufferSize, inputCount, 'uint8');
  newOrderIndex = zeros(stepBufferSize, inputCount, 'uint32');
  newNodes      = zeros(stepBufferSize, inputCount);

  %
  % The first two levels.
  %
  nodeCount = 1 + 2 * inputCount;

  levelIndex(1:nodeCount, :) = 1;
  nodes     (1:nodeCount, :) = 0.5;

  for i = 1:inputCount
    %
    % The left and right most nodes.
    %
    k = 1 + 2 * (i - 1) + 1;
    levelIndex(k:(k + 1), i) = 2;
    nodes     (k:(k + 1), i) = [ 0.0; 1.0 ];
  end

  %
  % Evaluate the function on the first two levels.
  %
  values(1:nodeCount, :) = f(nodes(1:nodeCount, :));

  [ startIndex(1, :), finishIndex(1, :), ~ ] = computeTimeIndex( ...
    values(1, timeRange), samplingInterval, agentCount, outputCount);

  surpluses (1, :) = values(1, :);
  surpluses2(1, :) = values(1, :).^2;

  %
  % Summarize what we have done so far.
  %
  level = 2;
  stableNodeCount = 1;
  oldNodeCount = 2 * inputCount;

  oldOrderIndex(1:oldNodeCount, :) = 1;
  for i = 1:inputCount
    %
    % NOTE: The order of the left node is already one;
    % therefore, we initialize only the right node.
    %
    oldOrderIndex(2 * (i - 1) + 2, i) = 3;
  end

  levelNodeCount = zeros(maximalLevel, 1);
  levelNodeCount(1) = 1;
  levelNodeCount(2) = 2 * inputCount;

  %
  % Now, the other levels.
  %
  while true
    verbose('Level %2d: stable %6d, old %6d, total %6d.\n', ...
      level, stableNodeCount, oldNodeCount, nodeCount);

    %
    % First, we always compute the surpluses of the old nodes.
    % These surpluses determine the parent nodes that are to be
    % refined.
    %
    oldNodeRange = (stableNodeCount + 1):(stableNodeCount + oldNodeCount);

    stableLevelIndex = levelIndex(1:stableNodeCount, :);
    intervals = 2.^(double(stableLevelIndex) - 1);
    inverseIntervals = 1.0 ./ intervals;

    delta = zeros(stableNodeCount, inputCount);
    for i = oldNodeRange
      for j = 1:inputCount
        delta(:, j) = abs(nodes(1:stableNodeCount, j) - nodes(i, j));
      end
      I = find(all(delta < inverseIntervals, 2));

      %
      % Ensure that all the (one-dimensional) basis functions at
      % the first level are equal to one.
      %
      bases = 1.0 - intervals(I, :) .* delta(I, :);
      bases(stableLevelIndex(I, :) == 1) = 1;
      bases = prod(bases, 2);

      approximatedTime = ...
        sum(bsxfun(@times, surpluses(I, timeRange), bases), 1);
      surpluses(i, timeRange) = values(i, timeRange) - approximatedTime;

      approximatedTime2 = ...
        sum(bsxfun(@times, surpluses2(I, timeRange), bases), 1);
      surpluses2(i, timeRange) = values(i, timeRange).^2 - approximatedTime2;

      [ startIndex(i, :), finishIndex(i, :), mapping ] = computeTimeIndex( ...
        values(i, timeRange), samplingInterval, agentCount, outputCount);

      for j = dataRange
        J = chooseSurpluses(mapping(j), j, ...
          startIndex(I, :), finishIndex(I, :));

        if isempty(J)
          surpluses(i, j) = values(i, j);
          surpluses2(i, j) = values(i, j).^2;
        else
          surpluses(i, j) = values(i, j) - ...
            sum(bsxfun(@times, surpluses(I(J), j), bases(J)), 1);

          surpluses2(i, j) = values(i, j).^2 - ...
            sum(bsxfun(@times, surpluses(I(J), j), bases(J)), 1);
        end
      end
    end

    %
    % If the current level is the last one, we do not try to add any
    % more nodes; just exit the loop.
    %
    if ~(level < maximalLevel), break; end

    %
    % Since we are allowed to go to the next level, we seek
    % for new nodes defined as children of the old nodes where
    % the corresponding surpluses violate the accuracy constraint.
    %
    newNodeCount = 0;
    stepBufferLimit = oldNodeCount * 2 * inputCount;

    %
    % Ensure that we have enough space.
    %
    addition = stepBufferLimit - stepBufferSize;
    if addition > 0
      %
      % We need more space.
      %
      oldOrderIndex = [ oldOrderIndex; ...
        zeros(addition, inputCount, 'uint32') ];
      newLevelIndex = [ newLevelIndex; ...
        zeros(addition, inputCount, 'uint8') ];
      newOrderIndex = [ newOrderIndex; ...
        zeros(addition, inputCount, 'uint32') ];
      newNodes      = [ newNodes; ...
        zeros(addition, inputCount) ];

      stepBufferSize = stepBufferSize + addition;
    end

    %
    % Adaptivity control.
    %
    switch adaptivityControl
    case 0 % Infinity norm of surpluses and surpluses2
      nodeContribution = max(abs(cat(2, ...
        surpluses (oldNodeRange, dataRange), ...
        surpluses2(oldNodeRange, dataRange))), [], 2);
    case 1 % Infinity norm of surpluses
      nodeContribution = max(abs( ...
        surpluses (oldNodeRange, dataRange)), [], 2);
    case 2 % Infinity norm of squared surpluses
      nodeContribution = max(abs( ...
        surpluses2(oldNodeRange, dataRange)), [], 2);
    otherwise
      assert(false);
    end

    for i = oldNodeRange
      if level >= minimalLevel && ...
        nodeContribution(i - stableNodeCount) < tolerance, continue; end

      %
      % So, the threshold is violated (or the minimal level has not been
      % reached yet); hence, we need to add all the neighbors.
      %
      currentLevelIndex = levelIndex(i, :);
      currentOrderIndex = oldOrderIndex(i - stableNodeCount, :);
      currentNode = nodes(i, :);

      for j = 1:inputCount
        [ childOrderIndex, childNodes ] = computeNeighbors( ...
          currentLevelIndex(j), currentOrderIndex(j));

        childCount = length(childOrderIndex);
        newNodeCount = newNodeCount + childCount;

        assert(newNodeCount <= stepBufferLimit);

        for k = 1:childCount
          l = newNodeCount - childCount + k;

          newLevelIndex(l, :) = currentLevelIndex;
          newLevelIndex(l, j) = currentLevelIndex(j) + 1;

          newOrderIndex(l, :) = currentOrderIndex;
          newOrderIndex(l, j) = childOrderIndex(k);

          newNodes(l, :) = currentNode;
          newNodes(l, j) = childNodes(k);
        end
      end
    end

    %
    % The new nodes have been identify, but they might not be unique.
    % Therefore, we need to filter out all duplicates.
    %
    [ uniqueNewNodes, I ] = unique(newNodes(1:newNodeCount, :), 'rows');
    uniqueNewLevelIndex = newLevelIndex(I, :);
    uniqueNewOrderIndex = newOrderIndex(I, :);

    newNodeCount = size(uniqueNewNodes, 1);

    %
    % If there are no more nodes to refine, we stop.
    %
    if newNodeCount == 0, break; end

    oldOrderIndex(1:newNodeCount, :) = uniqueNewOrderIndex;

    nodeCount = nodeCount + newNodeCount;

    addition = nodeCount - bufferSize;
    if addition > 0
      %
      % We need more space.
      %
      levelIndex = [ levelIndex; ...
        zeros(addition, inputCount, 'uint8') ];
      startIndex = [ startIndex; ...
        zeros(addition, inputCount, 'uint32') ];
      finishIndex = [ finishIndex; ...
        zeros(addition, inputCount, 'uint32') ];
      nodes       = [ nodes; ...
        zeros(addition, inputCount) ];
      values      = [ values; ...
        zeros(addition, outputCount) ];
      surpluses   = [ surpluses; ...
        zeros(addition, outputCount) ];
      surpluses2  = [ surpluses2; ...
        zeros(addition, outputCount) ];

      bufferSize = bufferSize + addition;
    end

    range = (nodeCount - newNodeCount + 1):nodeCount;

    levelIndex(range, :) = uniqueNewLevelIndex;
    nodes     (range, :) = uniqueNewNodes;
    values    (range, :) = f(uniqueNewNodes);

    oldNodeCount  = nodeCount - stableNodeCount - oldNodeCount;
    stableNodeCount = nodeCount - oldNodeCount;

    %
    % We go to the next level.
    %
    level = level + 1;
    levelNodeCount(level) = newNodeCount;
  end

  range = 1:nodeCount;

  levelIndex = levelIndex(range, :);
  startIndex = startIndex(range, :);
  finishIndex = finishIndex(range, :);

  nodes = nodes(range, :);

  surpluses = surpluses(range, :);
  surpluses2 = surpluses2(range, :);

  levelNodeCount = levelNodeCount(1:level);

  %
  % Now, we take care about the expected value and variance.
  %
  integrals = 2.^(1 - double(levelIndex));

  %
  % NOTE: We do not need the following line; keep for clarity.
  %
  % integrals(levelIndex == 1) = 1;
  %
  integrals(levelIndex == 2) = 0.25;
  integrals = prod(integrals, 2);

  expectation = sum(bsxfun(@times, surpluses, integrals), 1);
  variance = sum(bsxfun(@times, surpluses2, integrals), 1) - expectation.^2;

  %
  % Save the result.
  %
  this.inputCount = inputCount;
  this.outputCount = outputCount;
  this.agentCount = agentCount;

  this.samplingInterval = samplingInterval;

  this.level = level;
  this.nodeCount = nodeCount;
  this.levelNodeCount = levelNodeCount;

  this.levelIndex = levelIndex;
  this.startIndex = startIndex;
  this.finishIndex = finishIndex;

  this.nodes = nodes;
  this.surpluses = surpluses;

  this.expectation = expectation;
  this.variance = variance;

  %
  % Just for now.
  %
  this.expectation(dataRange) = 0;
  this.variance(dataRange) = 0;
end

function [ orderIndex, nodes ] = computeNeighbors(level, order)
  if level > 2
    orderIndex = uint32([ 2 * order - 2; 2 * order ]);
    nodes = double(orderIndex - 1) / 2^((double(level) + 1) - 1);
  elseif level == 2
    if order == 1
      orderIndex = uint32(2);
      nodes = 0.25;
    elseif order == 3
      orderIndex = uint32(4);
      nodes = 0.75;
    else
      assert(false);
    end
  elseif level == 1;
    assert(order == 1);
    orderIndex = uint32([ 1; 3 ]);
    nodes = [ 0.0; 1.0 ];
  else
    assert(false);
  end
end
