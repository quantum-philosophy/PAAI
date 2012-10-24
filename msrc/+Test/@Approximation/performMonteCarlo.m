function performMonteCarlo(this)
  Terminal.printHeader('Monte Carlo');

  fprintf('Number of samples: %d\n', this.sampleCount);

  filename = sprintf('%s_MC_%s_%s.mat', this.name, this.method, ...
    DataHash({ this.serialize(), this.sampleCount }));

  if File.exist(filename)
    warning('Loading cached data "%s".', filename);
    load(filename);
  else
    tic;
    switch this.method
    case 'PC'
      mcSamples = randn(this.sampleCount, this.inputDimension);
    otherwise
      mcSamples = rand(this.sampleCount, this.inputDimension);
    end
    mcData = this.evaluate(mcSamples);
    time = toc;
    save(filename, 'mcSamples', 'mcData', 'time', '-v7.3');
  end

  fprintf('Monte Carlo simulation: %.2f s\n', time);

  this.mcSamples = mcSamples;
  this.mcData = mcData;
end
