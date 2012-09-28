function interpolation
  init;

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

  boundaries = [ -4 * ones(dimension, 1), +4 * ones(dimension, 1) ];
  options = spset();

  fprintf('Dimension: %d\n', dimension);

  tic;
  z = spvals( ...
    @(varargin) compute( ...
      schedule, executionTime + transformation.evaluate(cell2mat(varargin))), ...
    dimension, boundaries, options);
  fprintf('Interpolation: %.2f s\n', toc);
end

function result = compute(schedule, executionTime)
  schedule.adjustExecutionTime(executionTime);
  result = max(schedule.startTime + schedule.executionTime);
end
