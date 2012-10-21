function solution = approximation
  setup;
  rng(0);

  use('Vendor', 'DataHash');

  %
  % ----------------------------------------------------------------------------
  % Configuration of the system
  % ----------------------------------------------------------------------------
  %
  header('Configuration of the system');

  independent = true;
  samplingInterval = 1e-4;

  [ ~, ~, functionName ] = File.trace;
  filename = sprintf('%s_input.mat', functionName);

  if File.exist(filename)
    load(filename);
  else
    method = 'PC';
    processorIndex = uint8(1);
    taskIndex = uint8(1);
  end

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
    'prompt', sprintf('Method to employ (PC, ASGC, HDMR) [%s]: ', method), ...
    'default', method);
  method = upper(method);

  processorIndex = Input.read( ...
    'prompt', sprintf('Processor to inspect (1-%d) [%d]: ', processorCount, processorIndex), ...
    'default', processorIndex);

  taskIndex = Input.read( ...
    'prompt', sprintf('Tasks to inspect (1-%d) [%s]: ', ...
      taskCount, Utils.toString(taskIndex)), ...
    'default', taskIndex, 'convert', 'uint8');

  save(filename, 'method', 'processorIndex', 'taskIndex', '-v7.3');

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
  % Definition of the problem
  % ----------------------------------------------------------------------------
  %
  dimensionCount = transformation.dimension;
  executionTime = schedule.executionTime;

  startTime = 0;
  endTime = duration(schedule);
  stepIndex = max(1, floor(startTime / samplingInterval)):floor(endTime / samplingInterval);
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
  % Configuration of the approximation method
  % ----------------------------------------------------------------------------
  %
  header('Configuration of the approximation method');

  additionalParameters = {};

  switch method
  case 'PC'
    polynomialOrder = 3;
    polynomialOrder = Input.read( ...
      'prompt', sprintf('Polynomial order [%d]: ', polynomialOrder), ...
      'default', polynomialOrder);

    quadratureOrder = polynomialOrder + 1;
    quadratureOrder = Input.read( ...
      'prompt', sprintf('Quadrature order [%d]: ', quadratureOrder), ...
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
      'adaptivityControl', 'NormNormExpectation', ...
      'tolerance', 1e-4, ...
      'maximalLevel', 10, ...
      'verbose', true);

    hdmrOptions = Options( ...
      'inputDimension', dimensionCount, ...
      'outputDimension', stepCount, ...
      'interpolantOptions', asgcOptions, ...
      'orderTolerance', 1e-3, ...
      'dimensionTolerance', 1e-3, ...
      'maximalOrder', 10, ...
      'verbose', true);
  otherwise
    error('The solution method is unknown.');
  end

  switch method
  case 'PC'
    display(chaosOptions);
  case 'ASGC'
    display(asgcOptions);
  case 'HDMR'
    display(hdmrOptions);
  otherwise
    assert(false);
  end

  %
  % ----------------------------------------------------------------------------
  % Construction of the approximation
  % ----------------------------------------------------------------------------
  %
  header('Construction of the approximation');

  filename = sprintf('%s_%s_%s.mat', functionName, method, ...
    DataHash({ processorCount, taskCount, processorIndex, taskIndex, ...
      samplingInterval, stepIndex, independent, additionalParameters }));

  if File.exist(filename)
    warning('Loading cached data "%s".', filename);
    load(filename);
  else
    profile on;
    profile clear;
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
    profile report;
    profile off;
    save(filename, 'solution', 'time', '-v7.3');
  end

  fprintf('Solution construction: %.2f s\n', time);
  display(solution);

  sdExpectation = Utils.toCelsius(solution.expectation);
  sdVariance = solution.variance;

  %
  % ----------------------------------------------------------------------------
  % Monte Carlo sampling
  % ----------------------------------------------------------------------------
  %
  header('Monte Carlo sampling');

  sampleCount = 1e4;
  fprintf('Number of samples: %d\n', sampleCount);

  filename = sprintf('%s_MC_%s.mat', functionName, ...
    DataHash({ processorCount, taskCount, processorIndex, taskIndex, ...
      samplingInterval, stepIndex, independent, sampleCount }));

  if File.exist(filename)
    warning('Loading cached data "%s".', filename);
    load(filename);
  else
    tic;
    mcData = compute(rand(sampleCount, dimensionCount));
    time = toc;
    save(filename, 'mcData', 'time', '-v7.3');
  end

  fprintf('Monte Carlo simulation: %.2f s\n', time);

  mcExpectation = Utils.toCelsius(mean(mcData, 1));
  mcVariance = var(mcData, [], 1);

  %
  % ----------------------------------------------------------------------------
  % Inspection of the approximated solution
  % ----------------------------------------------------------------------------
  %
  header('Inspection of the approximated solution');

  time = stepIndex * samplingInterval;

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
  % Have a look at the expected value and variance.
  %
  figure;

  color1 = Color.pick(1);
  color2 = Color.pick(2);

  subplot(2, 1, 1);
  line(time, mcExpectation, 'Color', color1);
  line(time, sdExpectation, 'Color', color2);
  Plot.title('%s [%s]: Expectation', method, title);
  Plot.label('Time, s', 'Temperature, C');
  Plot.limit(time);
  legend('Monte Carlo', 'Approximated');

  subplot(2, 1, 2);
  line(time, mcVariance, 'Color', color1);
  line(time, sdVariance, 'Color', color2);
  Plot.title('%s [%s]: Variance', method, title);
  Plot.label('Time, s', 'Temperature^2, C^2');
  Plot.limit(time);
  legend('Monte Carlo', 'Approximated');

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

  names = {};
  for k = 1:length(RVs)
    nodes = RVs(k) * ones(1, dimensionCount);
    one = Utils.toCelsius(compute(nodes));
    two = Utils.toCelsius(solution.evaluate(nodes));
    color = Color.pick(k);
    line(time, one, 'Color', color, 'Marker', 'o');
    line(time, two, 'Color', color, 'Marker', 'x');
    names{end + 1} = sprintf('Exact at %.2f', RVs(k));
    names{end + 1} = 'Approximated';
  end
  Plot.title('%s [%s]: Examples', method, title);
  Plot.label('Time, s', 'Temperature, C');
  Plot.limit(time);
  legend(names{:});

  %
  % Have a look at a time slice.
  %
  switch method
  case 'PC'
    rvs = transpose(-3:0.1:3);
  otherwise
    rvs = transpose(0:0.05:1);
  end

  rvIndex = uint8(1:dimensionCount);
  timeSlice = (startTime + endTime) / 2;
  while true
    if dimensionCount > 1
      rvIndex = Input.read( ...
        'prompt', sprintf('Independent RV to visualize [%s]: ', Utils.toString(rvIndex)), ...
        'default', rvIndex, 'convert', 'uint8');
      if any(rvIndex == 0), break; end
      if any(rvIndex < 0) || any(rvIndex > dimensionCount), continue; end
    end

    timeSlice = Input.read( ...
      'prompt', sprintf('The moment of time to visualize [%.3f s]: ', timeSlice), ...
      'default', timeSlice);
    if timeSlice == 0, break; end
    if timeSlice < time(1) || timeSlice > time(end), continue; end

    timeIndex = floor((timeSlice - startTime) / samplingInterval);

    figure;

    RVs = zeros(length(rvs), dimensionCount);
    for i = 1:length(rvIndex)
      RVs(:, rvIndex(i)) = rvs;
    end

    one = Utils.toCelsius(compute(RVs));
    one = one(:, timeIndex);
    two = Utils.toCelsius(solution.evaluate(RVs));
    two = two(:, timeIndex);

    line(rvs, one, 'Color', color1);
    line(rvs, two, 'Color', color2);

    switch method
    case 'PC'
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
        line(rvs, three, 'Color', color1, 'Marker', 'x');
      end
    end

    Plot.title('%s [%s]: Time slice', method, title);
    Plot.label('Random variable', 'Temperature, C');
    Plot.limit(rvs);
    legend('Exact', 'Approximated');
  end
end

function header(text)
  fprintf('--------------------------------------------------------------------------------\n');
  fprintf('%s\n', upper(text));
  fprintf('--------------------------------------------------------------------------------\n');
end
