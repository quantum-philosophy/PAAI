function interpolation
  setup;

  %
  % Construct a test case.
  %
  tic;
  [ platform, application, schedule, parameters ] = Test.Case.constructBeta('002_020');
  fprintf('Initialization: %.2f s\n', toc);

  %
  % Make the parameters independent.
  %
  tic;
  transformation = Transformation.Normal(parameters);
  fprintf('Transformation: %.2f s\n', toc);

  %
  % Shortcuts.
  %
  dimension = transformation.dimension;
  executionTime = schedule.executionTime;

  fprintf('Dimension: %d\n', dimension);

  f = @(u) compute(schedule, executionTime, ...
    transformation.evaluate(norminv(u)));

  tic;
  interpolant = AdaptiveCollocation(f, ...
    'inputDimension', dimension, 'maxLevel', 15, 'tolerance', 1e-2);
  fprintf('Interpolant construction: %.2f s\n', toc);
end

function result = compute(schedule, executionTime, addition)
  points = size(addition, 1);
  result = zeros(points, 1);
  for i = 1:points
    schedule.adjustExecutionTime(executionTime + addition(i, :));
    result(i) = max(schedule.startTime + schedule.executionTime);
  end
end
