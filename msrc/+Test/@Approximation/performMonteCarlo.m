function performMonteCarlo(this)
  fprintf('Number of samples: %d\n', this.sampleCount);

  filename = sprintf('%s_MC_%s_%s.mat', this.name, this.method, ...
    DataHash({ this.serialize(), this.sampleCount }));

  if File.exist(filename)
    warning('Loading cached data "%s".', filename);
    load(filename);
  else
    tic;
    mcSamples = this.transformation.distribution.sample( ...
      this.sampleCount, this.inputDimension);
    mcData = this.simulate(mcSamples);
    time = toc;
    save(filename, 'mcSamples', 'mcData', 'time', '-v7.3');
  end

  fprintf('Monte Carlo simulation: %.2f s\n', time);

  this.mcSamples = mcSamples;
  this.mcData = mcData;
end
