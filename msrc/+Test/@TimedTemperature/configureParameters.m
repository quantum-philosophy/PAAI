function configureParameters(this)
  configureParameters@Test.Temperature(this);

  this.timeRange = 1:this.taskCount;
  this.tempRange = (1 + this.taskCount):(this.outputDimension + this.taskCount);
  this.outputDimension = this.outputDimension + this.taskCount;
end
