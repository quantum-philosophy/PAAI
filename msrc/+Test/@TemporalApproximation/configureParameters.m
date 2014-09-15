function configureParameters(this)
  configureParameters@Test.Approximation(this);

  if this.timeSpan(end) == 0
    duration = max(this.schedule.startTime + this.schedule.executionTime);
    this.timeSpan(end) = duration;
  end

  firstIndex = max(1, floor(this.timeSpan(1) / this.samplingInterval));
  lastIndex = floor(this.timeSpan(end) / this.samplingInterval);
  lastIndex = floor(lastIndex / this.timeDivision) * this.timeDivision;

  this.stepIndex = firstIndex:this.timeDivision:lastIndex;

  this.outputCount = length(this.stepIndex);
end
