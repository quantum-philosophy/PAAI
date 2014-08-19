function visualizeApproximation(this)
  switch this.method
  case 'MC'
    title = sprintf('samples %d, time step %s s', ...
      this.sampleCount, num2str(this.samplingInterval));
  case 'PC'
    title = sprintf('polynomial order %d, quadrature order %d', ...
      this.approximation.order, this.methodOptions.quadratureOptions.order);
  case 'SC'
    title = sprintf('level %d, nodes %d', ...
      this.apOutput.level, this.apOutput.nodeCount);

    if this.inputCount < 3
      plot(this.approximation, this.apOutput);
    end
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
  Plot.title('%s [%s]: Expectation', this.method, title);
  Plot.label('Time, s');
  Plot.limit(time);

  if ~this.onlyMC && ~isempty(this.apExpectation)
    line(time, this.apExpectation, 'Color', apColor);
    line(time, mean(this.apData, 1), 'Color', apColor, 'LineStyle', '--');
    legend('Monte Carlo', ...
      'Approximation (analytical)', 'Approximation (empirical)');
  end

  figure;
  line(time, this.mcVariance, 'Color', mcColor);
  Plot.title('%s [%s]: Variance', this.method, title);
  Plot.label('Time, s');
  Plot.limit(time);

  if ~this.onlyMC && ~isempty(this.apVariance)
    line(time, this.apVariance, 'Color', apColor);
    line(time, var(this.apData, [], 1), 'Color', apColor, 'LineStyle', '--');
    legend('Monte Carlo', ...
      'Approximation (analytical)', 'Approximation (empirical)');
  end

  distribution = this.transformation.distribution;

  %
  % Have a look at sample paths.
  %
  k = 1;
  while Console.question('Have a look at a sample path? ')
    if k == 1
      sampleFigure = figure;
    end
    figure(sampleFigure);

    Plot.title('%s [%s]: Sample paths', this.method, title);
    Plot.label('Time, s');
    Plot.limit(time);

    sample = distribution.sample(1, this.inputCount);

    fprintf('Chosen sample: %s\n', String(sample));

    color = Color.random();

    mcdata = this.simulate(sample);
    line(time, mcdata, 'Color', color);

    if ~this.onlyMC
      apdata = this.approximate(sample);
      line(time, apdata, 'Color', color, 'LineStyle', '--');
    end

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
  while Console.question('Have a look at a sweep of random variables? ')
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
    line(rvSweep, mcdata, 'Color', mcColor);

    Plot.title('%s [%s]: Time slice', this.method, title);
    Plot.label('Random variable');
    Plot.limit(rvSweep);

    if ~this.onlyMC
      apdata = this.approximate(rvs);
      apdata = apdata(:, timeIndex);
      line(rvSweep, apdata, 'Color', apColor);
      legend('Monte Carlo', 'Approximation');
    end
  end

  %
  % Have a look at a PDF.
  %
  while Console.question('Have a look at a PDF? ')
    timeSlice = this.questions.request('timeSlice', 'default', timeSlice);
    timeIndex = timeToIndex(this, timeSlice);
    if ~timeIndex, continue; end

    this.questions.save();

    if this.onlyMC
      Plot.distribution(this.mcData(:, timeIndex), ...
        'draw', true, 'method', 'histogram', 'range', 'unbounded');
    else
      Utils.compareDistributions( ...
        this.mcData(:, timeIndex), this.apData(:, timeIndex), ...
        'draw', true, 'method', 'histogram', 'range', 'unbounded');
      legend('Monte Carlo', 'Approximation');
    end
  end
end

function index = timeToIndex(this, time)
  index = floor((time - this.timeSpan(1)) / ...
    this.samplingInterval / this.timeDivision);
  if index < 1 || index > length(this.stepIndex)
    index = 0;
  end
end
