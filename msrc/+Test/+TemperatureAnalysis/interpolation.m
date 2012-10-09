function interpolant = interpolation
  setup;
  includeLibrary('Vendor/DataHash');

  samplingInterval = 1e-4;
  sampleCount = 1e2;

  %
  % Configure the test case.
  %
  [ platform, application, floorplan, hotspotConfig, hotspotLine ] = ...
    Test.Case.request('samplingInterval', samplingInterval);

  processorCount = length(platform);
  taskCount = length(application);

  %
  % Pick a processing element.
  %
  processorIndex = 1;

  fprintf('  Processor to inspect (1-%d) [%d]: ', processorCount, processorIndex);
  out = input('');
  if ~isempty(out), processorIndex = out; end

  %
  % Pick a set of tasks.
  %
  taskIndex = 1;

  fprintf('  Tasks to inspect (1-%d) [[%d]]: ', taskCount, taskIndex);
  out = input('');
  if ~isempty(out), taskIndex = out; end

  %
  % Construct a schedule and a set of uncertain parameters.
  %
  [ schedule, parameters ] = Test.Case.constructBeta(platform, application, ...
    'taskIndex', taskIndex, 'alpha', 1.4, 'beta', 3, 'deviation', 0.7);

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

  filename = sprintf('HotSpot_interpolation_%s.mat', ...
    DataHash({ processorCount, taskCount, processorIndex, taskIndex, ...
      samplingInterval, stepCount }));

  if File.exist(filename)
    load(filename);
  else
    %
    % Construct an interpolant.
    %
    tic;
    interpolant = ASGC(@(u) compute(power, hotspot, schedule, ...
      executionTime, processorIndex, taskIndex, stepCount, ...
      transformation.evaluateUniform(u)), ...
      'inputDimension', dimensionCount, 'outputDimension', stepCount, ...
      'maxLevel', 10, 'tolerance', 1e-2);
    time = toc;

    save(filename, 'interpolant', 'time', '-v7.3');
  end

  fprintf('Interpolant construction: %.2f s\n', time);

  %
  % Assess and visualize the interpolant.
  %

  index = taskIndex(1);

  while true
    if dimensionCount > 1
      fprintf('  Task to visualize [%d]: ', index);
      out = input('');
      if ~isempty(out), index = out; end
    end

    position = find(taskIndex == index);
    if length(position) ~= 1
      index = taskIndex(1);
      continue;
    end

    uniformSamples = 0.5 * ones(sampleCount, dimensionCount);
    uniformSamples(:, position) = linspace(0, 1, sampleCount).';

    samples = transformation.evaluateUniform(uniformSamples);
    data = interpolant.evaluate(uniformSamples);

    figure;

    minStepCount = find(all(data, 1), 1, 'last');
    Z = convertKelvinToCelsius(data(:, 1:minStepCount));

    timeSpan = (1:minStepCount) * samplingInterval;
    [ X, Y ] = meshgrid(timeSpan, samples(:, position) + executionTime(index));

    mesh(X, Y, Z);
    colormap(Color.map(Z, 0, 100));
    colorbar;

    title(sprintf('Temperature of Core %d', processorIndex));

    xlabel('Time, s');
    ylabel(sprintf('Execution time of Task %d', index));
    zlabel('Temperature, C');

    xlim([ min(min(X)), max(max(X)) ]);
    ylim([ min(min(Y)), max(max(Y)) ]);

    view([ 0 90 ]);

    if dimensionCount == 1, break; end
  end
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
