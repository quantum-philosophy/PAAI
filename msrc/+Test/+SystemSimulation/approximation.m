function solution = approximation
  setup;
  rng(0);

  independent = false;

  use('Vendor', 'DataHash');

  prefix = 'SS';

  questions = Terminal.Questionnaire( ...
    sprintf('%s_questions.mat', prefix));

  questions.append('method', ...
    'description', 'the approximation method (PC, ASGC, HDMR)', ...
    'default', 'PC', ...
    'type', 'char');

  questions.append('taskIndex', ...
    'description', 'a task set to inspect', ...
    'default', uint8(1), ...
    'type', 'uint8');

  questions.append('rvIndex', ...
    'description', 'an independent RV to visualize', ...
    'type', 'uint8');

  questions.load();

  %
  % ----------------------------------------------------------------------------
  % Configuration of the system
  % ----------------------------------------------------------------------------
  %
  Terminal.printHeader('Test case configuration');

  %
  % Construct the test case.
  %
  [ platform, application, floorplan, hotspotConfig, hotspotLine ] = ...
    Test.Case.request('samplingInterval', 1e-4);

  processorCount = length(platform);
  taskCount = length(application);

  %
  % Conduct a short survey.
  %
  method = questions.request('method');
  taskIndex = questions.request('taskIndex');

  questions.save();

  method = upper(method);

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
  % ----------------------------------------------------------------------------
  % Definition of the problem
  % ----------------------------------------------------------------------------
  %
  inputDimension = transformation.dimension;
  outputDimension = taskCount;

  executionTime = schedule.executionTime;
  newExecutionTime = executionTime;
  function data = compute(standardRVs)
    variables = transformation.evaluate(standardRVs);

    pointCount = size(variables, 1);

    data = zeros(pointCount, outputDimension);

    for i = 1:pointCount
      newExecutionTime(taskIndex) = executionTime(taskIndex) + variables(i, :);
      newSchedule = Schedule.Dense(schedule, 'executionTime', newExecutionTime);
      data(i, :) = newSchedule.startTime;
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
    DataHash({ processorCount, taskCount, taskIndex, ...
      independent, additionalParameters }));

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

  sdExpectation = solution.expectation;
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
    DataHash({ processorCount, taskCount, taskIndex, ...
      independent, sampleCount }));

  if File.exist(filename)
    warning('Loading cached data "%s".', filename);
    load(filename);
  else
    tic;
    mcSamples = rand(sampleCount, inputDimension);
    mcData = compute(mcSamples);
    time = toc;
    save(filename, 'mcSamples', 'mcData', 'time', '-v7.3');
  end

  fprintf('Monte Carlo simulation: %.2f s\n', time);

  mcExpectation = mean(mcData, 1);
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
  % Have a look at a time slice.
  %
  switch method
  case 'PC'
    rvs = transpose(-3:0.1:3);
  otherwise
    rvs = transpose(0:0.05:1);
  end

  rvIndex = uint8(1:inputDimension);
  while true
    if inputDimension > 1
      rvIndex = questions.request('rvIndex', 'default', rvIndex);
      if any(rvIndex == 0), break; end
      if any(rvIndex < 0) || any(rvIndex > inputDimension), continue; end
    end

    questions.save();

    figure;

    RVs = zeros(length(rvs), inputDimension);
    for j = 1:length(rvIndex)
      RVs(:, rvIndex(j)) = rvs;
    end

    one = compute(RVs);
    two = solution.evaluate(RVs);

    line(rvs, one, 'Color', Color.pick(1), 'Marker', 'o');
    line(rvs, two, 'Color', Color.pick(2), 'Marker', 'x');

    Plot.title('%s [%s]', method, title);
    Plot.label('Random variable', 'Start time, s');
    Plot.limit(rvs);

    if inputDimension == 1, break; end
  end
end
