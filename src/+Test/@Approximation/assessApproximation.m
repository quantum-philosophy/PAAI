function assessApproximation(this)
  if ~isempty(this.apExpectation)
    fprintf('Expectation:\n');
    fprintf('  Normalized L2:   %.4e\n', ...
      Error.computeNL2(this.mcExpectation, this.apExpectation));
    fprintf('  Normalized RMSE: %.4e\n', ...
      Error.computeNRMSE(this.mcExpectation, this.apExpectation));
  end

  if ~isempty(this.apVariance)
    fprintf('Variance:\n');
    fprintf('  Normalized L2:   %.4e\n', ...
      Error.computeNL2(this.mcVariance, this.apVariance));
    fprintf('  Normalized RMSE: %.4e\n', ...
      Error.computeNRMSE(this.mcVariance, this.apVariance));
  end

  fprintf('Random sampling:\n');
  fprintf('  Normalized L2:   %.4e\n', ...
    Error.computeNL2(this.mcData, this.apData));
  fprintf('  Normalized RMSE: %.4e\n', ...
    Error.computeNRMSE(this.mcData, this.apData));
end
