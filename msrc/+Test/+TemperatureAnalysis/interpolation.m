function interpolant = interpolation
  setup;

  processorIndex = 1;
  taskIndex = 1;
  samplingInterval = 1e-4;
  sampleCount = 1e2;

  %
  % Configure the test case.
  %
  tic;
  [ platform, application, floorplan, hotspotConfig, hotspotLine ] = ...
    Test.Case.request('samplingInterval', samplingInterval);

  [ schedule, parameters ] = Test.Case.constructBeta(platform, application, ...
    'taskIndex', taskIndex, 'alpha', 1.4, 'beta', 3, 'deviation', 0.7);
  fprintf('Initialization: %.2f s\n', toc);

  %
  % Perform the probability transformation.
  %
  tic;
  transformation = ProbabilityTransformation.Normal(parameters);
  fprintf('Transformation: %.2f s\n', toc);

  %
  % Initialize the power computation.
  %
  power = PowerProfile(samplingInterval);

  %
  % Initialize the temperature simulator.
  %
  hotspot = HotSpot.Analytic(floorplan, hotspotConfig, hotspotLine);

  %
  % Shortcuts.
  %
  dimensionCount = transformation.dimension;
  executionTime = schedule.executionTime;

  stepCount = floor(duration(schedule) / samplingInterval);

  fprintf('Dimension: %d\n', dimensionCount);

  %
  % Construct an interpolant.
  %
  tic;
  interpolant = ASGC(@(u) compute(power, hotspot, schedule, ...
    executionTime, processorIndex, taskIndex, stepCount, ...
    transformation.evaluateUniform(u)), ...
    'inputDimension', dimensionCount, 'outputDimension', stepCount, ...
    'maxLevel', 10, 'tolerance', 1e-2);
  fprintf('Interpolant construction: %.2f s\n', toc);

  %
  % Assess the interpolant.
  %
  uniformSamples = linspace(0, 1, sampleCount).';
  samples = transformation.evaluateUniform(uniformSamples);
  data = interpolant.evaluate(uniformSamples);

  %
  % Display.
  %
  figure;

  minStepCount = find(all(data, 1), 1, 'last');
  Z = convertKelvinToCelsius(data(:, 1:minStepCount));

  timeSpan = (1:minStepCount) * samplingInterval;
  [ X, Y ] = meshgrid(timeSpan, samples + executionTime(taskIndex));

  mesh(X, Y, Z);
  colormap(Color.map);
  colorbar;

  title(sprintf('Temperature of Core %d', processorIndex));

  xlabel('Time, s');
  ylabel(sprintf('Execution time of Task %d', taskIndex));
  zlabel('Temperature, C');

  xlim([ min(min(X)), max(max(X)) ]);
  ylim([ min(min(Y)), max(max(Y)) ]);

  view([ 0 90 ]);
end

function result = compute(power, hotspot, ...
  schedule, executionTime, processorIndex, taskIndex, stepCount, delta)

  taskCount = size(executionTime, 2);
  [ pointCount, dimensionCount ] = size(delta);

  result = zeros(pointCount, stepCount);

  for i = 1:pointCount
    time = executionTime;
    time(taskIndex) = time(taskIndex) + delta(i, :);
    schedule.adjustExecutionTime(time);

    powerProfile = power.compute(schedule);
    temperatureProfile = hotspot.compute(powerProfile);

    count = min(stepCount, size(temperatureProfile, 2));
    result(i, 1:count) = temperatureProfile(processorIndex, 1:count);
  end
end
