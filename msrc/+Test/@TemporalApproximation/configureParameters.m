function configureParameters(this)
  configureParameters@Test.Approximation(this);

  if this.timeSpan(end) == 0
    this.timeSpan(end) = duration(this.schedule);
  end

  firstIndex = max(1, floor(this.timeSpan(1) / this.samplingInterval));
  lastIndex = floor(this.timeSpan(end) / this.samplingInterval);

  this.stepIndex = firstIndex:this.timeDivision:lastIndex;

  this.outputCount = length(this.stepIndex);
end
