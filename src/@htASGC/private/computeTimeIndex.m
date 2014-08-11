function [ startIndex, finishIndex, mapping ] = computeTimeIndex( ...
  time, dt, agentCount, outputCount)

  %
  % Ensure that the start times, which are smaller than a single time
  % step, result in ones instead of zeros (plus the number of agents).
  %
  startIndex = 1 + 2 * agentCount + ...
    uint32(floor(time(1:agentCount) / dt));

  %
  % Ensure that the finish times do not go beyond the scope of interest.
  %
  finishIndex = min(outputCount, 2 * agentCount + ...
    uint32(floor(time((agentCount + 1):end) / dt)));

  %
  % NOTE: The first `2 * agentCount' elements have no meaning.
  %
  mapping = zeros(1, outputCount, 'uint32');
  for i = 1:agentCount
    if startIndex(i) > outputCount, continue; end

    assert(all(mapping(startIndex(i):finishIndex(i)) == 0));
    mapping(startIndex(i):finishIndex(i)) = i;
  end
end
