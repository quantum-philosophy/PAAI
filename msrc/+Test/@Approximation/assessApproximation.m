function assessApproximation(this)
  approximation = this.approximation;

  mcSamples = this.mcSamples;
  mcData = this.mcData;

  mcExpectation = mean(mcData, 1);
  mcVariance = var(mcData, [], 1);

  apExpectation = this.apExpectation;
  apVariance = this.apVariance;

  fprintf('Expectation:\n');
  fprintf('  Normalized L2:   %.4e\n', ...
    Error.computeNL2(mcExpectation, apExpectation));
  fprintf('  Normalized RMSE: %.4e\n', ...
    Error.computeNRMSE(mcExpectation, apExpectation));

  fprintf('Variance:\n');
  fprintf('  Normalized L2:   %.4e\n', ...
    Error.computeNL2(mcVariance, apVariance));
  fprintf('  Normalized RMSE: %.4e\n', ...
    Error.computeNRMSE(mcVariance, apVariance));

  filename = sprintf('%s_%s_MC_%s.mat', this.name, this.method, ...
    DataHash({ this.serialize(), this.sampleCount, ...
      this.methodSerialization }));

  if File.exist(filename)
    warning('Loading cached data "%s".', filename);
    load(filename);
  else
    tic;
    apData = this.approximate(mcSamples);
    time = toc;
    save(filename, 'apData', 'time', '-v7.3');
  end

  fprintf('Evaluation of %d samples: %.2f s\n', this.sampleCount, time);

  fprintf('Random sampling:\n');
  fprintf('  Normalized L2:   %.4e\n', ...
    Error.computeNL2(mcData, apData));
  fprintf('  Normalized RMSE: %.4e\n', ...
    Error.computeNRMSE(mcData, apData));

  this.mcExpectation = mcExpectation;
  this.mcVariance = mcVariance;

  this.apData = apData;
end
