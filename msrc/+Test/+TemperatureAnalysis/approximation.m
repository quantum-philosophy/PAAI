function solution = approximation
  setup;
  rng(0);

  use('Vendor', 'DataHash');

  %
  % ----------------------------------------------------------------------------
  % Preliminary configuration
  % ----------------------------------------------------------------------------
  %
  independent = true;
  samplingInterval = 1e-4;

  method = 'PC';
  processorIndex = 1;
  taskIndex = 1;

  %
  % Construct the test case.
  %
  [ platform, application, floorplan, hotspotConfig, hotspotLine ] = ...
    Test.Case.request('samplingInterval', samplingInterval, 'silent', true);

  processorCount = length(platform);
  taskCount = length(application);

  %
  % Conduct a short survey.
  %
  method = Input.read( ...
    'prompt', sprintf('  Method to employ (PC, ASGC, HDMR) [%s]: ', method), ...
    'default', method);
  method = upper(method);

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
    'alpha', 1, 'beta', 1, 'deviation', 0.7);

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
  % ----------------------------------------------------------------------------
  % Problem definition
  % ----------------------------------------------------------------------------
  %
  dimensionCount = transformation.dimension;
  executionTime = schedule.executionTime;

  stepIndex = 1:floor(0.1 / samplingInterval);
  stepCount = length(stepIndex);

  newExecutionTime = executionTime;
  function data = compute(standardNormalRVs)
    variables = transformation.evaluate(standardNormalRVs);

    pointCount = size(variables, 1);

    data = zeros(pointCount, stepCount);

    for i = 1:pointCount
      newExecutionTime(taskIndex) = executionTime(taskIndex) + variables(i, :);
      newSchedule = Schedule.Dense(schedule, 'executionTime', newExecutionTime);
      newPowerProfile = power.compute(newSchedule);

      powerProfile = newPowerProfile(:, stepIndex);
      temperatureProfile = hotspot.compute(powerProfile);

      data(i, :) = temperatureProfile(processorIndex, :);
    end
  end

  %
  % ----------------------------------------------------------------------------
  % Method configuration
  % ----------------------------------------------------------------------------
  %
  additionalParameters = {};

  switch method
  case 'PC'
    polynomialOrder = 3;
    polynomialOrder = Input.read( ...
      'prompt', sprintf('  Polynomial order [%d]: ', polynomialOrder), ...
      'default', polynomialOrder);

    quadratureOrder = polynomialOrder + 1;
    quadratureOrder = Input.read( ...
      'prompt', sprintf('  Quadrature order [%d]: ', quadratureOrder), ...
      'default', quadratureOrder);

    quadratureOptions = Options( ...
      'name', 'Tensor', ...
      'dimension', dimensionCount, ...
      'order', quadratureOrder);

    chaosOptions = Options( ...
      'quadratureOptions', quadratureOptions, ...
      'inputDimension', dimensionCount, ...
      'outputDimension', stepCount, ...
      'order', polynomialOrder);

    additionalParameters{end + 1} = polynomialOrder;
    additionalParameters{end + 1} = quadratureOrder;
  case { 'ASGC', 'HDMR' }
    asgcOptions = Options( ...
      'inputDimension', dimensionCount, ...
      'outputDimension', stepCount, ...
      'adaptivityControl', 'InfNorm', ...
      'tolerance', 1e-3, ...
      'maximalLevel', 10, ...
      'verbose', true);

    hdmrOptions = Options( ...
      'inputDimension', dimensionCount, ...
      'outputDimension', stepCount, ...
      'interpolantOptions', asgcOptions, ...
      'orderTolerance', 1e-5, ...
      'dimensionTolerance', 1e-5, ...
      'maximalOrder', 10, ...
      'verbose', true);
  otherwise
    error('The solution method is unknown.');
  end

  %
  % ----------------------------------------------------------------------------
  % Approximation
  % ----------------------------------------------------------------------------
  %

  filename = sprintf('TemperatureAnalysis_PolynomialChaos_%s.mat', ...
    DataHash({ method, processorCount, taskCount, processorIndex, taskIndex, ...
      samplingInterval, stepCount, independent, additionalParameters }));

  if File.exist(filename)
    warning('Loading cached data "%s".', filename);
    load(filename);
  else
    tic;
    switch method
    case 'PC'
      solution = PolynomialChaos.ProbabilistHermite(@compute, chaosOptions);
    case 'ASGC'
      solution = ASGC(@compute, asgcOptions);
    case 'HDMR'
      solution = HDMR(@compute, hdmrOptions);
    otherwise
      error('The method is unknown.');
    end
    time = toc;
    save(filename, 'solution', 'time', '-v7.3');
  end

  fprintf('Solution construction: %.2f s\n', time);
  display(solution);

  %
  % ----------------------------------------------------------------------------
  % Inspection
  % ----------------------------------------------------------------------------
  %

  switch method
  case 'PC'
    title = sprintf('polynomial order %d, quadrature order %d', ...
      solution.order, quadratureOrder);
  case 'ASGC'
    title = sprintf('level %d, nodes %d', ...
      solution.level, solution.nodeCount);
  case 'HDMR'
    title = sprintf('order %d, interpolants %d, nodes %d', ...
      solution.order, length(solution.interpolants), solution.nodeCount);
  otherwise
    assert(false);
  end

  %
  % Have a look at some overall curves.
  %
  figure;

  switch method
  case 'PC'
    RVs = [ -0.50, 0.00, 0.50 ];
  otherwise
    RVs = [  0.25, 0.50, 0.75 ];
  end

  time = (1:stepCount) * samplingInterval;

  for k = 1:length(RVs)
    nodes = RVs(k) * ones(1, dimensionCount);
    one = Utils.toCelsius(compute(nodes));
    two = Utils.toCelsius(solution.evaluate(nodes));
    color = Color.pick(k);
    line(time, one, 'Color', color);
    line(time, two, 'Color', color, 'LineStyle', '--');
  end
  Plot.title('%s: %s', method, title);
  Plot.label('Time, s', 'Temperature, C');
  Plot.limit(time);

  %
  % Have a look at a time slice.
  %
  switch lower(method)
  case 'pc'
    rvs = transpose(-3:0.1:3);
  otherwise
    rvs = transpose(0:0.1:1);
  end

  rvIndex = 1;
  timeSlice = 0.033;
  while true
    if dimensionCount > 1
      rvIndex = Input.read( ...
        'prompt', sprintf('  Independent RV to visualize [%d]: ', rvIndex), ...
        'default', rvIndex);
      if rvIndex == 0, break; end
      if rvIndex < 0 || rvIndex > dimensionCount, continue; end
    end

    timeSlice = Input.read( ...
      'prompt', sprintf('  The moment of time to visualize [%.3f s]: ', timeSlice), ...
      'default', timeSlice);
    if timeSlice == 0, break; end
    if timeSlice < 0 || timeSlice > time(end), continue; end

    timeIndex = floor(timeSlice / samplingInterval);

    figure;

    RVs = zeros(length(rvs), dimensionCount);
    RVs(:, rvIndex) = rvs;

    one = Utils.toCelsius(compute(RVs));
    one = one(:, timeIndex);
    two = Utils.toCelsius(solution.evaluate(RVs));
    two = two(:, timeIndex);

    color = Color.pick(1);
    line(RVs, one, 'Color', color);
    line(RVs, two, 'Color', color, 'Marker', 'x');

    switch lower(method)
    case 'pc'
      if false && dimensionCount == 1
        %
        % Verification with the toolbox pmpack.
        %
        alternative = pseudospectral(@(standardNormalRVs) ...
          compute(standardNormalRVs), [ parameter('gaussian') ], polynomialOrder);
        three = zeros(size(one));
        for m = 1:length(RVs)
          three(m) = evaluate_expansion(alternative, RVs(m));
        end
        three = Utils.toCelsius(three);
        line(RVs, three, 'Color', color, 'Marker', 'o');
      end
    end

    Plot.title('%s: %s', method, title);
    Plot.label('Random variable', 'Temperature, C');
    Plot.limit(RVs);
  end
end
