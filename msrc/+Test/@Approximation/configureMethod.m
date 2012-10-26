function configureMethod(this)
  switch this.method
  case 'PC'
    this.methodOptions = Options( ...
      'quadratureOptions', Options( ...
        'name', 'Sparse', ...
        'dimension', this.inputDimension, ...
        'level', 3), ...
      'inputDimension', this.inputDimension, ...
      'outputDimension', this.outputDimension, ...
      'order', 2, ...
      this.methodOptions);
  case 'ASGC'
    this.methodOptions = Options( ...
      'inputDimension', this.inputDimension, ...
      'outputDimension', this.outputDimension, ...
      'adaptivityControl', 'NormNormExpectation', ...
      'tolerance', 1e-4, ...
      'maximalLevel', 10, ...
      'verbose', true, ...
      this.methodOptions);
  case 'HDMR'
    this.methodOptions = Options( ...
      'inputDimension', this.inputDimension, ...
      'outputDimension', this.outputDimension, ...
      'interpolantOptions', Options( ...
        'inputDimension', this.inputDimension, ...
        'outputDimension', this.outputDimension, ...
        'adaptivityControl', 'NormNormExpectation', ...
        'tolerance', 1e-4, ...
        'maximalLevel', 10, ...
        'verbose', true), ...
      'orderTolerance', 1e-3, ...
      'dimensionTolerance', 1e-3, ...
      'maximalOrder', 10, ...
      'verbose', true, ...
      this.methodOptions);
  otherwise
    assert(false);
  end
end
