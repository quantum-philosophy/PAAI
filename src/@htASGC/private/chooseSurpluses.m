function J = chooseSurpluses(i, j, startIndex, finishIndex)
  if i == 0
    %
    % There are no agents running at time j.
    %
    S = find(startIndex(:, i) > j);
    F = find(finishIndex(:, i) <= j);
    J = union(S, F);
  else
    %
    % There is one (and only one) agent running.
    %
    S = find(startIndex(:, i) <= j);
    F = find(finishIndex(:, i) > j);
    J = intersect(S, F);
  end
end
