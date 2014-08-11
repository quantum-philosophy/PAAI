function values = evaluate(this, newNodes)
  zeros = @uninit;

  %
  % Ensure the input is valid.
  %
  planeNewNodes = newNodes(:);
  assert(all(planeNewNodes >= 0) && all(planeNewNodes <= 1));

  inputCount = this.inputCount;
  outputCount = this.outputCount;
  agentCount = this.agentCount;

  samplingInterval = this.samplingInterval;

  levelIndex = this.levelIndex;
  startIndex = this.startIndex;
  finishIndex = this.finishIndex;

  nodes = this.nodes;
  surpluses = this.surpluses;

  timeRange = 1:(2 * agentCount);
  dataRange = (2 * agentCount + 1):outputCount;

  nodeCount = size(nodes, 1);

  newNodeCount = size(newNodes, 1);
  values = zeros(newNodeCount, outputCount);

  delta = zeros(nodeCount, inputCount);

  intervals = 2.^(double(levelIndex) - 1);
  inverseIntervals = 1.0 ./ intervals;

  for i = 1:newNodeCount
    for j = 1:inputCount
      delta(:, j) = abs(nodes(:, j) - newNodes(i, j));
    end
    I = find(all(delta < inverseIntervals, 2));

    bases = 1.0 - intervals(I, :) .* delta(I, :);
    bases(levelIndex(I, :) == 1) = 1;
    bases = prod(bases, 2);

    approximatedTime = ...
      sum(bsxfun(@times, surpluses(I, timeRange), bases), 1);
    values(i, timeRange) = approximatedTime;

    [ ~, ~, mapping ] = computeTimeIndex( ...
      approximatedTime, samplingInterval, agentCount, outputCount);

    for j = dataRange
      J = chooseSurpluses(mapping(j), j, ...
        startIndex(I, :), finishIndex(I, :));
      if isempty(J)
        assert(false);
      else
        values(i, j) = sum(bsxfun(@times, surpluses(I(J), j), bases(J)), 1);
      end
    end
  end
end
