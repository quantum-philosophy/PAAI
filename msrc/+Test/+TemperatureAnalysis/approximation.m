function approximation
  rng(0);

  setup;
  includeLibrary('Vendor/DataHash');

  samplingInterval = 1e-4;
  sampleCount = 1e2;

  %
  % Configure the test case.
  %
  [ platform, application, floorplan, hotspotConfig, hotspotLine ] = ...
    Test.Case.request('samplingInterval', samplingInterval, 'silent', true);

  processorCount = length(platform);
  taskCount = length(application);

  %
  % Pick a method.
  %
  method = 'ASGC';

  fprintf('  Method to employ (ASGC, MC) [%s]: ', method);
  method = Input.read('default', method, 'char', true, 'upper', true);

  %
  % Pick a processing element.
  %
  processorIndex = 1;

  fprintf('  Processor to inspect (1-%d) [%d]: ', processorCount, processorIndex);
  processorIndex = Input.read('default', processorIndex);

  %
  % Pick a set of tasks.
  %
  taskIndex = 1;

  fprintf('  Tasks to inspect (1-%d) [[%d]]: ', taskCount, taskIndex);
  taskIndex = Input.read('default', taskIndex);

  %
  % Construct a schedule and a set of uncertain parameters.
  %
  [ schedule, parameters ] = Test.Case.constructBeta(platform, application, ...
    'taskIndex', taskIndex, 'independent', true, ...
    'alpha', 1.4, 'beta', 3, 'deviation', 0.7);

  %
  % Perform the probability transformation.
  %
  transformation = ProbabilityTransformation.Normal(parameters);

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
  % ============================================================================
  %

  switch method
  case 'ASGC'
    filename = sprintf('HotSpot_approximation_%s.mat', ...
      DataHash({ processorCount, taskCount, processorIndex, taskIndex, ...
        samplingInterval, stepCount }));

    if File.exist(filename)
      load(filename);
    else
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
    display(interpolant);

    computeData = @(samples, uniformSamples) interpolant.evaluate(uniformSamples);
  case 'MC'
    computeData = @(samples, uniformSamples) compute(power, hotspot, ...
      schedule, executionTime, processorIndex, taskIndex, stepCount, ...
      transformation.evaluateUniform(uniformSamples));
  otherwise
    error('The method is unknown.');
  end

  %
  % ============================================================================
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

    data = computeData(samples, uniformSamples);

    figure;

    minStepCount = find(all(data, 1), 1, 'last');
    Z = convertKelvinToCelsius(data(:, 1:minStepCount));

    timeSpan = (1:minStepCount) * samplingInterval;
    [ X, Y ] = meshgrid(timeSpan, samples(:, position) + executionTime(index));

    mesh(X, Y, Z);
    colormap(Color.map(Z, 0, 100));
    colorbar;

    title(sprintf('%s: Temperature of Core %d', method, processorIndex));

    xlabel('Time, s');
    ylabel(sprintf('Execution time of Task %d', index));
    zlabel('Temperature, C');

    xlim([ min(min(X)), max(max(X)) ]);
    ylim([ min(min(Y)), max(max(Y)) ]);

    view([ 0 90 ]);

    if dimensionCount == 1, break; end
  end
end

function data = compute(power, hotspot, ...
  schedule, executionTime, processorIndex, taskIndex, stepCount, delta)

  taskCount = size(executionTime, 2);
  [ pointCount, dimensionCount ] = size(delta);

  data = zeros(pointCount, stepCount);

  for i = 1:pointCount
    time = executionTime;
    time(taskIndex) = time(taskIndex) + delta(i, :);
    schedule.adjustExecutionTime(time);

    powerProfile = power.compute(schedule);
    temperatureProfile = hotspot.compute(powerProfile);

    count = min(stepCount, size(temperatureProfile, 2));
    data(i, 1:count) = temperatureProfile(processorIndex, 1:count);
  end
end
