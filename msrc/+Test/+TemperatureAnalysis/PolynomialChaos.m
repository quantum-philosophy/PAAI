function PolynomialChaos
  setup;

  independent = true;
  samplingInterval = 1e-4;

  processorIndex = 1;
  taskIndex = 1;
  polynomialOrder = 3;

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

  quadratureOrder = polynomialOrder + 1;
  quadratureOrder = Input.read( ...
    'prompt', sprintf('  Quadrature order [%d]: ', quadratureOrder), ...
    'default', quadratureOrder);

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
  % Shortcuts.
  %
  dimension = transformation.dimension;
  executionTime = schedule.executionTime;

  stepIndex = 1:floor(0.1 / samplingInterval);
  stepCount = length(stepIndex);

  %
  % Target.
  %
  newExecutionTime = executionTime;
  function data = compute(standardNormalRVs)
    variables = transformation.evaluateNative(standardNormalRVs);

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
  % ############################################################################
  %

  %
  % Polynomial chaos for the whole curve.
  %
  quadratureOptions = Options( ...
    'name', 'Tensor', ...
    'dimension', dimension, ...
    'order', quadratureOrder);
  chaosOptions = Options( ...
    'quadratureOptions', quadratureOptions, ...
    'dimension', dimension, ...
    'codimension', stepCount, ...
    'order', polynomialOrder);
  chaos = PolynomialChaos.ProbabilistHermite(chaosOptions);

  display(chaos);

  tic;
  coefficients = chaos.expand(@compute);
  fprintf('Expansion construction: %.2f s\n', toc);

  %
  % Have a look at the curve.
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
  % ############################################################################
  %

  timeSlice = 0.033;
  stepIndex = floor(timeSlice / samplingInterval);
  stepCount = 1;

  %
  % Polynomial chaos for a time slice.
  %
  chaosOptions.codimension = 1;
  chaos = PolynomialChaos.ProbabilistHermite(chaosOptions);

  display(chaos);

  tic;
  coefficients = chaos.expand(@compute);
  fprintf('Expansion construction: %.2f s\n', toc);

  %
  % Have a look at the slice.
  %
  figure;

  RVs = transpose(-3:0.1:3);

  one = Utils.toCelsius(compute(RVs));
  two = Utils.toCelsius(chaos.evaluate(coefficients, RVs));

  color = Color.pick(1);
  line(RVs, one,   'Color', color);
  line(RVs, two,   'Color', color, 'Marker', 'x');

  if false
    %
    % Verification with pmpack.
    %
    solution = pseudospectral(@(standardNormalRVs) ...
      compute(standardNormalRVs), [ parameter('gaussian') ], polynomialOrder);
    three = zeros(size(one));
    for m = 1:length(RVs)
      three(m) = evaluate_expansion(solution, RVs(m));
    end
    three = Utils.toCelsius(three);
    line(RVs, three, 'Color', color, 'Marker', 'o');
  end

  Plot.title('Time %.2f s, polynomial order %d, quadrature order %d', ...
    timeSlice, polynomialOrder, quadratureOrder);
  Plot.label('Random variable, s', 'Temperature, C');
  Plot.limit(RVs);
end
