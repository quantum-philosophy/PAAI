function assessApproximation(this)
  Terminal.printHeader('Assess the approximation');

  approximation = this.approximation;

  mcSamples = this.mcSamples;
  mcData = this.mcData;

  mcExpectation = mean(mcData, 1);
  mcVariance = var(mcData, [], 1);

  fprintf('Expectation:\n');
  fprintf('  Normalized L2:   %.4e\n', ...
    Error.computeNL2(mcExpectation, approximation.expectation));
  fprintf('  Normalized RMSE: %.4e\n', ...
    Error.computeNRMSE(mcExpectation, approximation.expectation));

  fprintf('Variance:\n');
  fprintf('  Normalized L2:   %.4e\n', ...
    Error.computeNL2(mcVariance, approximation.variance));
  fprintf('  Normalized RMSE: %.4e\n', ...
    Error.computeNRMSE(mcVariance, approximation.variance));

  tic;
  apData = approximation.evaluate(mcSamples);
  fprintf('Evaluation of %d samples: %.2f s\n', this.sampleCount, toc);

  fprintf('Random sampling:\n');
  fprintf('  Normalized L2:   %.4e\n', ...
    Error.computeNL2(mcData, apData));
  fprintf('  Normalized RMSE: %.4e\n', ...
    Error.computeNRMSE(mcData, apData));

  this.mcExpectation = mcExpectation;
  this.mcVariance = mcVariance;
end
