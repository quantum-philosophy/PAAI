function visualizeApproximation(this)
  approximation = this.approximation;
  distribution = this.transformation.distribution;

  switch this.method
  case 'PC'
    title = sprintf('polynomial order %d, quadrature level %d', ...
      approximation.order, this.methodOptions.quadratureOptions.level);
  case 'ASGC'
    title = sprintf('level %d, nodes %d', ...
      approximation.level, approximation.nodeCount);

    if this.inputDimension < 3
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
  Plot.title('%s [%s]: Expectation', this.method, title);
  Plot.label('Time, s');
  Plot.limit(time);
  legend('Monte Carlo', 'Approximation');

  figure;
  line(time, this.mcVariance, 'Color', mcColor);
  line(time, this.apVariance, 'Color', apColor);
  Plot.title('%s [%s]: Variance', this.method, title);
  Plot.label('Time, s');
  Plot.limit(time);
  legend('Monte Carlo', 'Approximation');

  %
  % Have a look at random traces.
  %
  k = 1;
  while Terminal.question('Generate a sample path? ')
    if k == 1
      sampleFigure = figure;
    end
    figure(sampleFigure);

    Plot.title('%s [%s]: Sample paths', this.method, title);
    Plot.label('Time, s');
    Plot.limit(time);

    sample = distribution.sample(1, this.inputDimension);

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

  rvIndex = uint8(1:this.inputDimension);
  timeSlice = (this.timeSpan(1) + this.timeSpan(end)) / 2;
  while Terminal.question('Sweep a set of random variables? ')
    if this.inputDimension > 1
      rvIndex = this.questions.request('rvIndex', 'default', rvIndex);
      if any(rvIndex < 0) || any(rvIndex > this.inputDimension), continue; end
    end

    timeSlice = this.questions.request('timeSlice', 'default', timeSlice);
    if timeSlice < time(1) || timeSlice > time(end), continue; end

    this.questions.save();

    timeIndex = floor((timeSlice - this.timeSpan(1)) / ...
      this.samplingInterval / this.timeDivision);

    figure;

    rvs = zeros(length(rvSweep), this.inputDimension);
    for j = 1:length(rvIndex)
      rvs(:, rvIndex(j)) = rvSweep;
    end

    mcData = this.simulate(rvs);
    mcData = mcData(:, timeIndex);

    apData = this.approximate(rvs);
    apData = apData(:, timeIndex);

    line(rvSweep, mcData, 'Color', mcColor);
    line(rvSweep, apData, 'Color', apColor);

    Plot.title('%s [%s]: Time slice', this.method, title);
    Plot.label('Random variable');
    Plot.limit(rvSweep);
    legend('Exact', 'Approximation');
  end
end
