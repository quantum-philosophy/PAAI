function data = evaluate(this, rvs)
  processorIndex = this.processorIndex;
  taskIndex = this.taskIndex;
  power = this.power;
  hotspot = this.hotspot;
  schedule = this.schedule;

  timeRange = this.timeRange;
  tempRange = this.tempRange;

  rvs = this.transformation.evaluate(rvs);
  pointCount = size(rvs, 1);
  data = zeros(pointCount, this.outputDimension);

  newExecutionTime = schedule.executionTime;
  for i = 1:pointCount
    newExecutionTime(taskIndex) = ...
      schedule.executionTime(taskIndex) + rvs(i, :);
    newSchedule = Schedule.Dense(schedule, ...
      'executionTime', newExecutionTime);
    newPowerProfile = power.compute(newSchedule);

    powerProfile = newPowerProfile(:, this.stepIndex);
    temperatureProfile = hotspot.compute(powerProfile);

    data(i, timeRange) = newSchedule.startTime;
    data(i, tempRange) = temperatureProfile(processorIndex, :);
  end
end
