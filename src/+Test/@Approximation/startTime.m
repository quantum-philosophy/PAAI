function solution = approximation
  setup;
  rng(0);

  independent = false;

  use('Vendor', 'DataHash');

  prefix = 'SS';

  questions = Questionnaire( ...
    sprintf('%s_questions.mat', prefix));

  questions.append('method', ...
    'description', 'the approximation method (PC, SC)', ...
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
  Print.header('Test case configuration');

  %
  % Construct the test case.
  %
  [platform, application, floorplan, hotspotConfig, hotspotLine] = ...
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
  [schedule, parameters] = Test.Case.constructBeta(platform, application, ...
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
  inputCount = transformation.dimension;
  outputCount = taskCount;

  executionTime = schedule.executionTime;
  newExecutionTime = executionTime;
  function data = compute(standardRVs)
    variables = transformation.evaluate(standardRVs);

    pointCount = size(variables, 1);

    data = zeros(pointCount, outputCount);

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
  Print.header('Configuration of the approximation method');

  additionalParameters = {};

  switch method
  case 'PC'
    questions.append('polynomialOrder', ...
      'description', 'the polynomial order', ...
      'default', 3);

    questions.append('quadratureLevel', ...
      'description', 'the quadrature order');

    questions.load();

    polynomialOrder = questions.request('polynomialOrder');
    quadratureLevel = questions.request('quadratureLevel', ...
      'default', polynomialOrder);

    questions.save();

    quadratureOptions = Options( ...
      'name', 'Tensor', ...
      'dimension', inputCount, ...
      'level', quadratureLevel);

    chaosOptions = Options( ...
      'quadratureOptions', quadratureOptions, ...
      'inputCount', inputCount, ...
      'outputCount', outputCount, ...
      'order', polynomialOrder);

    additionalParameters{end + 1} = polynomialOrder;
    additionalParameters{end + 1} = quadratureLevel;
  case 'SC'
    scOptions = Options( ...
      'inputCount', inputCount, ...
      'outputCount', outputCount, ...
      'absoluteTolerance', 1e-4, ...
      'relativeTolerance', 1e-2, ...
      'maximalLevel', 10, ...
      'verbose', true);
  otherwise
    error('The solution method is unknown.');
  end

  switch method
  case 'PC'
    display(chaosOptions);
  case 'SC'
    display(scOptions);
  otherwise
    assert(false);
  end

  %
  % ----------------------------------------------------------------------------
  % Construction of the approximation
  % ----------------------------------------------------------------------------
  %
  Print.header('Construction of the approximation');

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
      solution = PolynomialChaos(@compute, chaosOptions);
    case 'SC'
      solution = StochasticCollocation(@compute, scOptions);
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
  Print.header('Monte Carlo sampling');

  sampleCount = 1e4;
  fprintf('Number of samples: %d\n', sampleCount);

  filename = sprintf('%s_MC_%s_%s.mat', prefix, method, ...
    DataHash({ processorCount, taskCount, taskIndex, ...
      independent, sampleCount }));

  if File.exist(filename)
    warning('Loading cached data "%s".', filename);
    load(filename);
  else
    tic;
    mcSamples = rand(sampleCount, inputCount);
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
  Print.header('Inspection of the approximated solution');

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
    title = sprintf('polynomial order %d, quadrature level %d', ...
      solution.order, quadratureLevel);
  case 'SC'
    title = sprintf('level %d, nodes %d', ...
      solution.level, solution.nodeCount);
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

  rvIndex = uint8(1:inputCount);
  while true
    if inputCount > 1
      rvIndex = questions.request('rvIndex', 'default', rvIndex);
      if any(rvIndex == 0), break; end
      if any(rvIndex < 0) || any(rvIndex > inputCount), continue; end
    end

    questions.save();

    figure;

    RVs = zeros(length(rvs), inputCount);
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

    if inputCount == 1, break; end
  end
end
