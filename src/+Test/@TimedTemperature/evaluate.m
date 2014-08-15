function data = evaluate(this, rvs)
  processorIndex = this.processorIndex;
  taskIndex = this.taskIndex;

  power = this.power;
  temperature = this.temperature;

  scheduler = this.scheduler;
  schedule = this.schedule;
  arguments = { schedule.mapping, schedule.priority, schedule.order, [] };

  timeRange = this.timeRange;
  dataRange = this.dataRange;

  rvs = this.transformation.evaluate(rvs);
  pointCount = size(rvs, 1);
  data = zeros(pointCount, this.outputCount);

  newExecutionTime = schedule.executionTime;
  for i = 1:pointCount
    newExecutionTime(taskIndex) = ...
      schedule.executionTime(taskIndex) + rvs(i, :);
    newSchedule = scheduler.compute(arguments{:}, newExecutionTime);
    newPowerProfile = power.compute(newSchedule);

    powerProfile = newPowerProfile(:, this.stepIndex);
    temperatureProfile = temperature.compute(powerProfile);

    newSchedule = scheduler.decode(newSchedule);

    data(i, timeRange) = ...
      [newSchedule.startTime, newSchedule.startTime + newExecutionTime];
    data(i, dataRange) = temperatureProfile(processorIndex, :);
  end
end
