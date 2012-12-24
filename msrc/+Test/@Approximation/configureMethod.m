function configureMethod(this)
  switch this.method
  case 'PC'
    this.methodOptions = Options( ...
      'quadratureOptions', Options( ...
        'method', 'sparse', ...
        'dimension', this.inputCount, ...
        'order', 3), ...
      'inputCount', this.inputCount, ...
      'outputCount', this.outputCount, ...
      'order', 2, ...
      this.methodOptions);

    this.methodSerialization{end + 1} = ...
      this.methodOptions.order;
    this.methodSerialization{end + 1} = ...
      this.methodOptions.quadratureOptions.order;
  case 'ASGC'
    this.methodOptions = Options( ...
      'inputCount', this.inputCount, ...
      'outputCount', this.outputCount, ...
      'adaptivityControl', 'NormNormExpectation', ...
      'tolerance', 1e-4, ...
      'maximalLevel', 10, ...
      'verbose', true, ...
      this.methodOptions);
  case 'HDMR'
    this.methodOptions = Options( ...
      'inputCount', this.inputCount, ...
      'outputCount', this.outputCount, ...
      'interpolantOptions', Options( ...
        'inputCount', this.inputCount, ...
        'outputCount', this.outputCount, ...
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