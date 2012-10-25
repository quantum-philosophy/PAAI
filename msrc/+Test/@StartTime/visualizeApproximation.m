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

  switch this.method
  case 'PC'
    rvs = transpose(-3:0.1:3);
  otherwise
    rvs = transpose(0:0.05:1);
  end

  rvIndex = uint8(1:this.inputDimension);
  while true
    if this.inputDimension > 1
      rvIndex = this.questions.request('rvIndex', 'default', rvIndex);
      if any(rvIndex == 0), break; end
      if any(rvIndex < 0) || any(rvIndex > this.inputDimension), continue; end
    end

    this.questions.save();

    figure;

    RVs = zeros(length(rvs), this.inputDimension);
    for j = 1:length(rvIndex)
      RVs(:, rvIndex(j)) = rvs;
    end

    one = this.simulate(RVs);
    two = this.approximate(RVs);

    line(rvs, one, 'Color', Color.pick(1), 'Marker', 'o');
    line(rvs, two, 'Color', Color.pick(2), 'Marker', 'x');

    Plot.title('%s [%s]', this.method, title);
    Plot.label('Random variable', 'Start time, s');
    Plot.limit(rvs);

    if this.inputDimension == 1, break; end
  end
end
