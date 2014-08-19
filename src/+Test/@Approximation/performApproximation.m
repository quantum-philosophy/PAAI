function performApproximation(this)
  filename = File.temporal(sprintf('%s_%s_%s.mat', this.name, ...
    this.method, DataHash({ this.serialize(), this.methodSerialization })));

  if File.exist(filename)
    warning('Loading cached data "%s".', filename);
    load(filename);
  else
    tic;
    switch this.method
    case 'PC'
      approximation = PolynomialChaos(this.methodOptions);
      apOutput = approximation.construct(@this.evaluate);
      apStats = approximation.analyze(apOutput);
    case 'SC'
      approximation = StochasticCollocation(this.methodOptions);
      apOutput = approximation.construct(@this.evaluate);
      apStats = approximation.analyze(apOutput);
    otherwise
      assert(false);
    end
    time = toc;
    save(filename, 'approximation', 'apOutput', 'apStats', 'time', '-v7.3');
  end

  fprintf('Approximation construction: %.2f s\n', time);

  this.approximation = approximation;

  this.apOutput = apOutput;
  this.apExpectation = apStats.expectation;
  this.apVariance = apStats.variance;

  filename = File.temporal(sprintf('%s_%s_MC_%s.mat', this.name, ...
    this.method, DataHash({ this.serialize(), this.sampleCount, ...
      this.methodSerialization })));

  if File.exist(filename)
    warning('Loading cached data "%s".', filename);
    load(filename);
  else
    tic;
    apData = this.approximate(this.mcSamples);
    time = toc;
    save(filename, 'apData', 'time', '-v7.3');
  end

  fprintf('Approximation evaluation:   %.2f s (%d samples)\n', time, ...
    this.sampleCount);

  this.apData = apData;
end
