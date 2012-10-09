function interpolant = interpolation
  setup;

  %
  % Construct a test case.
  %
  tic;
  [ platform, application ] = Test.Case.request();
  [ schedule, parameters ] = ...
    Test.Case.constructBeta(platform, application, 'taskIndex', 1);
  fprintf('Initialization: %.2f s\n', toc);

  %
  % Make the parameters independent.
  %
  tic;
  transformation = ProbabilityTransformation.Normal(parameters);
  fprintf('Transformation: %.2f s\n', toc);

  %
  % Shortcuts.
  %
  dimensionCount = transformation.dimension;
  executionTime = schedule.executionTime;

  fprintf('Dimension: %d\n', dimensionCount);

  tic;
  interpolant = ASGC(@(u) compute(schedule, executionTime, ...
    transformation.evaluateUniform(u)), ...
    'inputDimension', dimensionCount, ...
    'maxLevel', 20, 'tolerance', 1e-4);
  fprintf('Interpolant construction: %.2f s\n', toc);

  display(interpolant);
  plot(interpolant);
end

function result = compute(schedule, executionTime, delta)
  taskCount = size(executionTime, 2);
  [ pointCount, dimensionCount ] = size(delta);

  result = zeros(pointCount, 1);

  for i = 1:pointCount
    time = executionTime;
    time(1) = time(1) + delta(i);
    schedule.adjustExecutionTime(time);
    result(i) = max(schedule.startTime + schedule.executionTime);
  end
end
