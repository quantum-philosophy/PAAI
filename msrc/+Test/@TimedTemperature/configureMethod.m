function configureMethod(this)
  configureMethod@Test.Temperature(this);

  switch this.method
  case 'ASGC'
    this.methodOptions.set( ...
      'adaptivityRange', this.timeRange);
    this.methodOptions.adaptivityControl = 'InfNormSurpluses2';
    this.methodOptions.tolerance = 1e-6;
  case 'HDMR'
    this.methodOptions.interpolantOptions.set( ...
      'adaptivityRange', this.timeRange);
  otherwise
    assert(false);
  end
end
