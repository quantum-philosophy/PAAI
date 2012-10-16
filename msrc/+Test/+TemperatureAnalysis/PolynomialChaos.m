function PolynomialChaos
  setup;

  independent = true;
  samplingInterval = 1e-4;

  processorIndex = 1;
  taskIndex = 1;
  polynomialOrder = 3;
  quadratureLevel = 5;

  %
  % Configure the test case.
  %
  [ platform, application, floorplan, hotspotConfig, hotspotLine ] = ...
    Test.Case.request('samplingInterval', samplingInterval, 'silent', true);

  processorCount = length(platform);
  taskCount = length(application);

  %
  % A questionnaire.
  %
  processorIndex = Input.read( ...
    'prompt', sprintf('  Processor to inspect (1-%d) [%d]: ', processorCount, processorIndex), ...
    'default', processorIndex);

  taskIndex = Input.read( ...
    'prompt', sprintf('  Tasks to inspect (1-%d) [[%d]]: ', taskCount, taskIndex), ...
    'default', taskIndex);

  polynomialOrder = Input.read( ...
    'prompt', sprintf('  Polynomial order [%d]: ', polynomialOrder), ...
    'default', polynomialOrder);

  quadratureLevel = Input.read( ...
    'prompt', sprintf('  Quadrature level [%d]: ', quadratureLevel), ...
    'default', quadratureLevel);

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
  dimension = transformation.dimension;
  executionTime = schedule.executionTime;

  stepCount = floor(duration(schedule) / samplingInterval);
  stepCount = floor(0.1 / samplingInterval);

  %
  % Target.
  %
  newExecutionTime = executionTime;
  newPowerProfile = zeros(processorCount, stepCount);
  function data = compute(standardNormalRVs)
    variables = transformation.evaluateNative(standardNormalRVs);

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
  % Polynomial chaos.
  %
  qdOptions = Options( ...
    'rules', 'GaussHermite', ...
    'level', quadratureLevel);
  pcOptions = Options( ...
    'quadratureName', 'Tensor', ...
    'quadratureOptions', qdOptions, ...
    'dimension', dimension, ...
    'codimension', stepCount, ...
    'order', polynomialOrder);
  chaos = PolynomialChaos.Hermite(pcOptions);

  display(chaos);

  tic;
  coefficients = chaos.expand(@compute);
  fprintf('Expansion construction: %.2f s\n', toc);

  %
  % Have a look at the algorithm.
  %
  figure;

  RVs = [ -0.5, 0.0, +0.5 ];
  time = (1:stepCount) * samplingInterval;

  for k = 1:length(RVs)
    nodes = RVs(k) * ones(dimension, 1);
    one = Utils.toCelsius(compute(nodes));
    two = Utils.toCelsius(chaos.evaluate(coefficients, nodes));
    color = Color.pick(k);
    line(time, one, 'Color', color);
    line(time, two, 'Color', color, 'LineStyle', '--');
  end
  Plot.label('Time, s', 'Temperature, C');
  Plot.limit(time);

  %
  % Have a look at a time slice.
  %
  figure;

  RVs = transpose(-1:0.1:1);
  time = [ 0.033 ];

  for k = 1:length(time)
    l = floor(time / samplingInterval);
    one = Utils.toCelsius(compute(RVs));
    one = one(:, l);
    two = Utils.toCelsius(chaos.evaluate(coefficients(:, l), RVs));
    color = Color.pick(k);
    line(RVs, one, 'Color', color);
    line(RVs, two, 'Color', color, 'LineStyle', '--');
  end
  Plot.title('Polynomial order %d, quadrature level %d', ...
    polynomialOrder, quadratureLevel);
  Plot.label('Random variable, s', 'Temperature, C');
  Plot.limit(RVs);
end
