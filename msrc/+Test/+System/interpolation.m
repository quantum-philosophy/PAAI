function interpolant = interpolation
  setup;

  %
  % Construct a test case.
  %
  tic;
  [ platform, application, schedule, parameters ] = Test.Case.constructBeta('002_020', 1);
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
    transformation.evaluateUniform(u));

  tic;
  interpolant = AdaptiveCollocation(f, ...
    'inputDimension', dimension, 'maxLevel', 20, 'tolerance', 1e-4);
  fprintf('Interpolant construction: %.2f s\n', toc);

  display(interpolant);
  plot(interpolant);
end

function result = compute(schedule, executionTime, addition)
  taskCount = size(executionTime, 2);
  [ points, dimension ] = size(addition);

  result = zeros(points, 1);

  for i = 1:points
    schedule.adjustExecutionTime(executionTime + [ addition(i), zeros(1, taskCount - dimension) ]);
    result(i) = max(schedule.startTime + schedule.executionTime);
  end
end
