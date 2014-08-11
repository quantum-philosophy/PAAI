function performMonteCarlo(this)
  fprintf('Number of samples: %d\n', this.sampleCount);

  filename = File.temporal(sprintf('%s_MC_%s_%s.mat', this.name, ...
    this.method, DataHash({ this.serialize(), this.sampleCount })));

  if File.exist(filename)
    warning('Loading cached data "%s".', filename);
    load(filename);
  else
    tic;
    mcSamples = this.transformation.distribution.sample( ...
      this.sampleCount, this.inputCount);
    mcData = this.simulate(mcSamples);
    time = toc;
    save(filename, 'mcSamples', 'mcData', 'time', '-v7.3');
  end

  fprintf('Monte Carlo simulation: %.2f s\n', time);

  this.mcSamples = mcSamples;
  this.mcData = mcData;

  this.mcExpectation = mean(mcData, 1);
  this.mcVariance = var(mcData, [], 1);
end
