function solution = approximation
  setup;
  rng(0);

  independent = true;
  samplingInterval = 1e-4;
  timeDivision = 2;

  use('Vendor', 'DataHash');

  prefix = 'TA';

  questions = Terminal.Questionnaire( ...
    sprintf('%s_questions.mat', prefix));

  questions.append('method', ...
    'description', 'the approximation method (PC, ASGC, HDMR)', ...
    'default', 'PC', ...
    'type', 'char');

  questions.append('processorIndex', ...
    'description', 'a processor to inspect', ...
    'default', uint8(1), ...
    'type', 'uint8');

  questions.append('taskIndex', ...
    'description', 'a task set to inspect', ...
    'default', uint8(1), ...
    'type', 'uint8');

  questions.append('timeSpan', ...
    'description', 'a time span', ...
    'default', [ 0, 0 ], ...
    'format', '%.3f');

  questions.append('rvIndex', ...
    'description', 'an independent RV to visualize', ...
    'type', 'uint8');

  questions.append('timeSlice', ...
    'description', 'a moment of time to visualize', ...
    'format', '%.3f');

  questions.load();

  %
  % ----------------------------------------------------------------------------
  % Configuration of the system
  % ----------------------------------------------------------------------------
  %
  Terminal.printHeader('Configuration of the system');

  %
  % Construct the test case.
  %
  [ platform, application, floorplan, hotspotConfig, hotspotLine ] = ...
    Test.Case.request('samplingInterval', samplingInterval);

  processorCount = length(platform);
  taskCount = length(application);

  %
  % Conduct a short survey.
  %
  method = questions.request('method');
  processorIndex = questions.request('processorIndex');
  taskIndex = questions.request('taskIndex');
  timeSpan = questions.request('timeSpan');

  questions.save();

  method = upper(method);

  %
  % Construct a schedule and a set of uncertain parameters.
  %
  [ schedule, parameters ] = Test.Case.constructBeta(platform, application, ...
    'taskIndex', taskIndex, 'independent', independent, ...
    'alpha', 1, 'beta', 1, 'deviation', 0.2);

  %
  % Perform the probability transformation.
  %
  transformation = ProbabilityTransformation.Uniform(parameters);

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
  if timeSpan(end) == 0
    timeSpan(end) = duration(schedule);
  end

  firstIndex = max(1, floor(timeSpan(1) / samplingInterval));
  lastIndex = floor(timeSpan(end) / samplingInterval);

  stepIndex = firstIndex:timeDivision:lastIndex;

  inputDimension = transformation.dimension;
  outputDimension = length(stepIndex);

  executionTime = schedule.executionTime;
  newExecutionTime = executionTime;
  function data = compute(standardRVs)
    variables = transformation.evaluate(standardRVs);

    pointCount = size(variables, 1);

    data = zeros(pointCount, outputDimension);

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
  Terminal.printHeader('Configuration of the approximation method');

  additionalParameters = {};

  switch method
  case 'PC'
    questions.append('polynomialOrder', ...
      'description', 'the polynomial order', ...
      'default', 3);

    questions.append('quadratureOrder', ...
      'description', 'the quadrature order');

    questions.load();

    polynomialOrder = questions.request('polynomialOrder');
    quadratureOrder = questions.request('quadratureOrder', ...
      'default', polynomialOrder + 1);

    questions.save();

    quadratureOptions = Options( ...
      'name', 'Tensor', ...
      'dimension', inputDimension, ...
      'order', quadratureOrder);

    chaosOptions = Options( ...
      'quadratureOptions', quadratureOptions, ...
      'inputDimension', inputDimension, ...
      'outputDimension', outputDimension, ...
      'order', polynomialOrder);

    additionalParameters{end + 1} = polynomialOrder;
    additionalParameters{end + 1} = quadratureOrder;
  case { 'ASGC', 'HDMR' }
    asgcOptions = Options( ...
      'inputDimension', inputDimension, ...
      'outputDimension', outputDimension, ...
      'adaptivityControl', 'NormNormExpectation', ...
      'tolerance', 1e-4, ...
      'maximalLevel', 10, ...
      'verbose', true);

    hdmrOptions = Options( ...
      'inputDimension', inputDimension, ...
      'outputDimension', outputDimension, ...
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
  Terminal.printHeader('Construction of the approximation');

  filename = sprintf('%s_%s_%s.mat', prefix, method, ...
    DataHash({ processorCount, taskCount, processorIndex, taskIndex, ...
      timeSpan, samplingInterval, stepIndex, independent, additionalParameters }));

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

  sdExpectation = Utils.toCelsius(solution.expectation);
  sdVariance    = solution.variance;

  %
  % ----------------------------------------------------------------------------
  % Monte Carlo sampling
  % ----------------------------------------------------------------------------
  %
  Terminal.printHeader('Monte Carlo sampling');

  sampleCount = 1e4;
  fprintf('Number of samples: %d\n', sampleCount);

  filename = sprintf('%s_MC_%s.mat', prefix, ...
    DataHash({ processorCount, taskCount, processorIndex, taskIndex, ...
      timeSpan, samplingInterval, stepIndex, independent, sampleCount }));

  if File.exist(filename)
    warning('Loading cached data "%s".', filename);
    load(filename);
  else
    tic;
    switch method
    case 'PC'
      mcSamples = randn(sampleCount, inputDimension);
    otherwise
      mcSamples = rand(sampleCount, inputDimension);
    end
    mcData = compute(mcSamples);
    time = toc;
    save(filename, 'mcSamples', 'mcData', 'time', '-v7.3');
  end

  fprintf('Monte Carlo simulation: %.2f s\n', time);

  mcExpectation = Utils.toCelsius(mean(mcData, 1));
  mcVariance = var(mcData, [], 1);

  %
  % ----------------------------------------------------------------------------
  % Inspection of the approximated solution
  % ----------------------------------------------------------------------------
  %
  Terminal.printHeader('Inspection of the approximated solution');

  fprintf('Expectation:\n');
  fprintf('  Normalized L2:   %.4e\n', ...
    Error.computeNL2(mcExpectation, sdExpectation));
  fprintf('  Normalized RMSE: %.4e\n', ...
    Error.computeNRMSE(mcExpectation, sdExpectation));

  fprintf('Variance:\n');
  fprintf('  Normalized L2:   %.4e\n', ...
    Error.computeNL2(mcVariance, sdVariance));
  fprintf('  Normalized RMSE: %.4e\n', ...
    Error.computeNRMSE(mcVariance, sdVariance));

  tic;
  sdData = solution.evaluate(mcSamples);
  fprintf('Evaluation of %d samples: %.2f s\n', sampleCount, toc);

  fprintf('Random sampling:\n');
  fprintf('  Normalized L2:   %.4e\n', ...
    Error.computeNL2(mcData, sdData));
  fprintf('  Normalized RMSE: %.4e\n', ...
    Error.computeNRMSE(mcData, sdData));

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
  color1 = Color.pick(1);
  color2 = Color.pick(2);

  figure;
  line(time, mcExpectation, 'Color', color1);
  line(time, sdExpectation, 'Color', color2);
  Plot.title('%s [%s]: Expectation', method, title);
  Plot.label('Time, s', 'Temperature, C');
  Plot.limit(time);
  legend('Monte Carlo', 'Approximated');

  figure;
  line(time, mcVariance, 'Color', color1);
  line(time, sdVariance, 'Color', color2);
  Plot.title('%s [%s]: Variance', method, title);
  Plot.label('Time, s', 'Temperature^2, C^2');
  Plot.limit(time);
  legend('Monte Carlo', 'Approximated');

  %
  % Have a look at some overall curves.
  %

  k = 1;
  while Terminal.question('Generate a sample path? ')
    if k == 1
      sampleFigure = figure;
    end
    figure(sampleFigure);

    Plot.title('%s [%s]: Sample paths', method, title);
    Plot.label('Time, s', 'Temperature, C');
    Plot.limit(time);

    switch method
    case 'PC'
      sample = randn(1, inputDimension);
    otherwise
      sample = rand(1, inputDimension);
    end

    fprintf('Chosen sample: %s\n', Utils.toString(sample));

    one = Utils.toCelsius(compute(sample));
    two = Utils.toCelsius(solution.evaluate(sample));

    color = Color.random();

    line(time, one, 'Color', color);
    line(time, smooth(two, 10), 'Color', color, 'LineStyle', '--');

    k = k + 1;
  end

  %
  % Have a look at a time slice.
  %
  switch method
  case 'PC'
    rvs = transpose(-3:0.1:3);
  otherwise
    rvs = transpose(0:0.05:1);
  end

  rvIndex = uint8(1:inputDimension);
  timeSlice = (timeSpan(1) + timeSpan(end)) / 2;
  while true
    if inputDimension > 1
      rvIndex = questions.request('rvIndex', 'default', rvIndex);
      if any(rvIndex == 0), break; end
      if any(rvIndex < 0) || any(rvIndex > inputDimension), continue; end
    end

    timeSlice = questions.request('timeSlice', 'default', timeSlice);
    if timeSlice == 0, break; end
    if timeSlice < time(1) || timeSlice > time(end), continue; end

    questions.save();

    timeIndex = floor((timeSlice - timeSpan(1)) / samplingInterval / timeDivision);

    figure;

    RVs = zeros(length(rvs), inputDimension);
    for j = 1:length(rvIndex)
      RVs(:, rvIndex(j)) = rvs;
    end

    one = Utils.toCelsius(compute(RVs));
    one = one(:, timeIndex);
    two = Utils.toCelsius(solution.evaluate(RVs));
    two = two(:, timeIndex);

    line(rvs, one, 'Color', color1);
    line(rvs, two, 'Color', color2);

    switch method
    case 'PC'
      if false && inputDimension == 1
        %
        % Verification with the toolbox pmpack.
        %
        alternative = pseudospectral(@(standardRVs) ...
          compute(standardRVs), parameter('gaussian'), polynomialOrder);
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
