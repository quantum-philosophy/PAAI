function configureParameters(this)
  configureParameters@Test.Temperature(this);

  this.outputCount = this.outputCount + 2 * this.taskCount;

  this.timeRange = 1:(2 * this.taskCount);
  this.dataRange = (1 + 2 * this.taskCount):this.outputCount;
end
