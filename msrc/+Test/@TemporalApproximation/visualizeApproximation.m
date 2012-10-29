function visualizeApproximation(this)
  approximation = this.approximation;
  distribution = this.transformation.distribution;

  mcData = this.mcData;
  apData = this.apData;

  switch this.method
  case 'PC'
    title = sprintf('polynomial order %d, quadrature level %d', ...
      approximation.order, this.methodOptions.quadratureOptions.level);
  case 'ASGC'
    title = sprintf('level %d, nodes %d', ...
      approximation.level, approximation.nodeCount);

    if this.inputCount < 3
      plot(approximation);
    end
  case 'HDMR'
    title = sprintf('order %d, interpolants %d, nodes %d', ...
      approximation.order, length(approximation.interpolants), ...
      approximation.nodeCount);
  otherwise
    assert(false);
  end

  time = this.stepIndex * this.samplingInterval;

  %
  % Have a look at the expected value and variance.
  %
  mcColor = Color.pick(1);
  apColor = Color.pick(2);

  figure;
  line(time, this.mcExpectation, 'Color', mcColor);
  line(time, this.apExpectation, 'Color', apColor);
  line(time, mean(apData, 1), 'Color', apColor, 'LineStyle', '--');
  Plot.title('%s [%s]: Expectation', this.method, title);
  Plot.label('Time, s');
  Plot.limit(time);
  legend('Monte Carlo', ...
    'Approximation (analytical)', 'Approximation (empirical)');

  figure;
  line(time, this.mcVariance, 'Color', mcColor);
  line(time, this.apVariance, 'Color', apColor);
  line(time, var(apData, [], 1), 'Color', apColor, 'LineStyle', '--');
  Plot.title('%s [%s]: Variance', this.method, title);
  Plot.label('Time, s');
  Plot.limit(time);
  legend('Monte Carlo', ...
    'Approximation (analytical)', 'Approximation (empirical)');

  %
  % Have a look at sample paths.
  %
  k = 1;
  while Terminal.question('Have a look at a sample path? ')
    if k == 1
      sampleFigure = figure;
    end
    figure(sampleFigure);

    Plot.title('%s [%s]: Sample paths', this.method, title);
    Plot.label('Time, s');
    Plot.limit(time);

    sample = distribution.sample(1, this.inputCount);

    fprintf('Chosen sample: %s\n', Utils.toString(sample));

    one = this.simulate(sample);
    two = this.approximate(sample);

    color = Color.random();

    line(time, one, 'Color', color);
    line(time, two, 'Color', color, 'LineStyle', '--');

    k = k + 1;
  end

  this.questions.autoreply(false);

  %
  % Have a look at a time slice.
  %
  support = distribution.support;
  if support(1) == -Inf
    support(1) = distribution.expectation - ...
      2 * sqrt(distribution.variance);
  end
  if support(2) == Inf
    support(2) = distribution.expectation + ...
      2 * sqrt(distribution.variance);
  end
  rvSweep = transpose(linspace(support(1), support(end), 50));

  rvIndex = uint8(1:this.inputCount);
  timeSlice = (this.timeSpan(1) + this.timeSpan(end)) / 2;
  while Terminal.question('Have a look at a sweep of random variables? ')
    if this.inputCount > 1
      rvIndex = this.questions.request('rvIndex', 'default', rvIndex);
      if any(rvIndex < 0) || any(rvIndex > this.inputCount), continue; end
    end

    timeSlice = this.questions.request('timeSlice', 'default', timeSlice);
    timeIndex = timeToIndex(this, timeSlice);
    if ~timeIndex, continue; end

    this.questions.save();

    figure;

    rvs = zeros(length(rvSweep), this.inputCount);
    for j = 1:length(rvIndex)
      rvs(:, rvIndex(j)) = rvSweep;
    end

    mcdata = this.simulate(rvs);
    mcdata = mcdata(:, timeIndex);

    apdata = this.approximate(rvs);
    apdata = apdata(:, timeIndex);

    line(rvSweep, mcdata, 'Color', mcColor);
    line(rvSweep, apdata, 'Color', apColor);

    Plot.title('%s [%s]: Time slice', this.method, title);
    Plot.label('Random variable');
    Plot.limit(rvSweep);
    legend('Exact', 'Approximation');
  end

  %
  % Have a look at a PDF.
  %
  while Terminal.question('Have a look at a PDF? ')
    timeSlice = this.questions.request('timeSlice', 'default', timeSlice);
    timeIndex = timeToIndex(this, timeSlice);
    if ~timeIndex, continue; end

    this.questions.save();

    compareData(mcData(:, timeIndex), apData(:, timeIndex), ...
      'draw', true, 'method', 'histogram', 'range', 'unbounded');
  end
end

function index = timeToIndex(this, time)
  index = floor((time - this.timeSpan(1)) / ...
    this.samplingInterval / this.timeDivision);
  if index < 1 || index > length(this.stepIndex)
    index = 0;
  end
end
