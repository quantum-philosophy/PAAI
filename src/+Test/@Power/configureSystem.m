function configureSystem(this)
  configureSystem@Test.Approximation(this);
  this.power = DynamicPower( ...
    'platform', this.platform, ...
    'application', this.application, ...
    'samplingInterval', this.samplingInterval);
end
