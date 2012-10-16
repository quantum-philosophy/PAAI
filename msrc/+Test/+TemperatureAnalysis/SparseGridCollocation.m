function interpolant = SparseGridCollocation
  rng(0);

  setup;
  use('Vendor', 'DataHash');

  independent = true;
  samplingInterval = 1e-4;
  sampleCount = 1e2;

  processorIndex = 1;
  taskIndex = 1;

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
  method = 'HDMR';

  fprintf('  Method to employ (HDMR, ASGC, MC) [%s]: ', method);
  method = Input.read('default', method, 'char', true, 'upper', true);

  %
  % A questionnaire.
  %
  processorIndex = Input.read( ...
    'prompt', sprintf('  Processor to inspect (1-%d) [%d]: ', processorCount, processorIndex), ...
    'default', processorIndex);

  taskIndex = Input.read( ...
    'prompt', sprintf('  Tasks to inspect (1-%d) [[%d]]: ', taskCount, taskIndex), ...
    'default', taskIndex);

  %
  % Construct a schedule and a set of uncertain parameters.
  %
  [ schedule, parameters ] = Test.Case.constructBeta(platform, application, ...
    'taskIndex', taskIndex, 'independent', independent, ...
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
  stepCount = floor(0.06 / samplingInterval);

  %
  % Target.
  %
  newExecutionTime = executionTime;
  newPowerProfile = zeros(processorCount, stepCount);
  function data = compute(standardUniformRVs)
    cutUniformRVs = (1 - 2 * 1e-6) * standardUniformRVs + 1e-6;
    variables = transformation.evaluateUniform(cutUniformRVs);

    pointCount = size(variables, 1);

    data = zeros(pointCount, stepCount);

    for i = 1:pointCount
      newExecutionTime(taskIndex) = executionTime(taskIndex) + variables(i, :);
      newSchedule = Schedule.Dense(schedule, 'executionTime', newExecutionTime);

      powerProfile = power.compute(newSchedule);
      count = min(stepCount, size(newPowerProfile, 2));

      newPowerProfile(:, 1:count) = powerProfile(:, 1:count);
      newPowerProfile(:, (count + 1):end) = 0;

      newTemperatureProfile = hotspot.compute(newPowerProfile);

      data(i, :) = newTemperatureProfile(processorIndex, :);
    end
  end

  %
  % ============================================================================
  %

  filename = sprintf('TemperatureAnalysis_SparseGridCollocation_%s.mat', ...
    DataHash({ processorCount, taskCount, processorIndex, taskIndex, ...
      samplingInterval, stepCount, independent, method }));

  asgcOptions = Options( ...
    'inputDimension', dimensionCount, 'outputDimension', stepCount, ...
    'adaptivityControl', 'norm', 'minLevel', 2, 'maxLevel', 10, ...
    'tolerance', 1e-4);

  hdmrOptions = Options( ...
    'inputDimension', dimensionCount, 'outputDimension', stepCount, ...
    'maxOrder', 10, 'interpolantOptions', asgcOptions, ...
    'orderTolerance', 1e-5, 'dimensionTolerance', 1e-5);

  switch method
  case 'HDMR'
    if File.exist(filename)
      warning('Loading cached data "%s".', filename);
      load(filename);
    else
      tic;
      interpolant = HDMR(@compute, hdmrOptions);
      time = toc;
      save(filename, 'interpolant', 'time', '-v7.3');
    end

    fprintf('HDMR construction: %.2f s\n', time);
    display(interpolant);

    computeData = @(uniformSamples) interpolant.evaluate(uniformSamples);
  case 'ASGC'
    asgcOptions.adaptivityControl = 'norm';
    asgcOptions.maxLevel = 12;
    asgcOptions.set('verbose', true);
    asgcOptions.tolerance = 1e-4;

    if File.exist(filename)
      warning('Loading cached data "%s".', filename);
      load(filename);
    else
      tic;
      interpolant = ASGC(@compute, asgcOptions);
      time = toc;
      save(filename, 'interpolant', 'time', '-v7.3');
    end

    fprintf('ASGC construction: %.2f s\n', time);
    display(interpolant);
    if dimensionCount <= 2, plot(interpolant); end

    computeData = @(u) interpolant.evaluate(u);
  case 'MC'
    interpolant = [];
    computeData = @compute;
  otherwise
    error('The method is unknown.');
  end

  figure;

  trials = [ 0.4, 0.5 ];
  x = (1:stepCount) * samplingInterval;

  for i = 1:length(trials)
    u = trials(i) * ones(1, dimensionCount);
    one = Utils.toCelsius(compute(u));
    two = Utils.toCelsius(computeData(u));
    color = Color.pick(i);
    line(x, one, 'Color', color);
    line(x, two, 'Color', color, 'LineStyle', '--');
  end

  %
  % ============================================================================
  %

  position = 1;
  while true
    if dimensionCount > 1
      fprintf('  Independent RV to visualize: ');
      position = Input.read;
      if isempty(position), break; end
      if position < 1 || position > dimensionCount, continue; end
    end

    uniformSamples = 0.5 * ones(sampleCount, dimensionCount);
    uniformSamples(:, position) = linspace(0, 1, sampleCount).';

    data = computeData(uniformSamples);

    figure;

    minStepCount = find(all(data, 1), 1, 'last');
    Z = Utils.toCelsius(data(:, 1:minStepCount));

    timeSpan = (1:minStepCount) * samplingInterval;
    [ X, Y ] = meshgrid(timeSpan, uniformSamples(:, position));

    mesh(X, Y, Z);
    colormap(Color.map(Z, 0, 100));
    colorbar;

    Plot.title('%s: Temperature of Core %d', method, processorIndex);
    Plot.label('Time, s', ...
      sprintf('Independent variable %d', position), 'Temperature, C');
    Plot.limit(X, Y);

    view([ 0 90 ]);

    if dimensionCount == 1, break; end
  end
end
