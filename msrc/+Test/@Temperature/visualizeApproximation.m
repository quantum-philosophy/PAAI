function visualizeApproximation(this)
  approximation = this.approximation;

  switch this.method
  case 'PC'
    title = sprintf('polynomial order %d, quadrature order %d', ...
      approximation.order, this.methodOptions.quadratureOptions.order);
  case 'ASGC'
    title = sprintf('level %d, nodes %d', ...
      approximation.level, approximation.nodeCount);
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
  color1 = Color.pick(1);
  color2 = Color.pick(2);

  figure;
  line(time, this.mcExpectation, 'Color', color1);
  line(time, approximation.expectation, 'Color', color2);
  Plot.title('%s [%s]: Expectation', this.method, title);
  Plot.label('Time, s', 'Temperature, C');
  Plot.limit(time);
  legend('Monte Carlo', 'Approximation');

  figure;
  line(time, this.mcVariance, 'Color', color1);
  line(time, approximation.variance, 'Color', color2);
  Plot.title('%s [%s]: Variance', this.method, title);
  Plot.label('Time, s', 'Temperature^2, C^2');
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
    Plot.label('Time, s', 'Temperature, C');
    Plot.limit(time);

    switch this.method
    case 'PC'
      sample = randn(1, this.inputDimension);
    otherwise
      sample = rand(1, this.inputDimension);
    end

    fprintf('Chosen sample: %s\n', Utils.toString(sample));

    one = Utils.toCelsius(this.evaluate(sample));
    two = Utils.toCelsius(approximation.evaluate(sample));

    color = Color.random();

    line(time, one, 'Color', color);
    line(time, two, 'Color', color, 'LineStyle', '--');

    k = k + 1;
  end

  %
  % Have a look at a time slice.
  %
  switch this.method
  case 'PC'
    rvs = transpose(-3:0.1:3);
  otherwise
    rvs = transpose(0:0.05:1);
  end

  this.questions.autoreply(false);

  rvIndex = uint8(1:this.inputDimension);
  timeSlice = (this.timeSpan(1) + this.timeSpan(end)) / 2;
  while true
    if this.inputDimension > 1
      rvIndex = this.questions.request('rvIndex', 'default', rvIndex);
      if any(rvIndex == 0), break; end
      if any(rvIndex < 0) || any(rvIndex > this.inputDimension), continue; end
    end

    timeSlice = this.questions.request('timeSlice', 'default', timeSlice);
    if timeSlice == 0, break; end
    if timeSlice < time(1) || timeSlice > time(end), continue; end

    this.questions.save();

    timeIndex = floor((timeSlice - this.timeSpan(1)) / ...
      this.samplingInterval / this.timeDivision);

    figure;

    RVs = zeros(length(rvs), this.inputDimension);
    for j = 1:length(rvIndex)
      RVs(:, rvIndex(j)) = rvs;
    end

    one = Utils.toCelsius(this.evaluate(RVs));
    one = one(:, timeIndex);
    two = Utils.toCelsius(approximation.evaluate(RVs));
    two = two(:, timeIndex);

    line(rvs, one, 'Color', color1);
    line(rvs, two, 'Color', color2);

    Plot.title('%s [%s]: Time slice', this.method, title);
    Plot.label('Random variable', 'Temperature, C');
    Plot.limit(rvs);
    legend('Exact', 'Approximation');
  end
end
