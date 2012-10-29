function configureMethod(this)
  configureMethod@Test.Temperature(this);

  switch this.method
  case 'ASGC'
    this.methodOptions.set('agentCount', this.taskCount);
    this.methodOptions.set('samplingInterval', this.samplingInterval);
  otherwise
    assert(false);
  end
end
