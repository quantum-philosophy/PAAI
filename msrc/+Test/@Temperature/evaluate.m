function data = evaluate(this, rvs)
  processorIndex = this.processorIndex;
  taskIndex = this.taskIndex;
  power = this.power;
  hotspot = this.hotspot;
  schedule = this.schedule;
  stepIndex = this.stepIndex;

  rvs = this.transformation.evaluate(rvs);
  pointCount = size(rvs, 1);
  data = zeros(pointCount, this.outputCount);

  parfor i = 1:pointCount
    newExecutionTime = schedule.executionTime;
    newExecutionTime(taskIndex) = ...
      schedule.executionTime(taskIndex) + rvs(i, :);
    newSchedule = Schedule.Dense(schedule, ...
      'executionTime', newExecutionTime);

    powerProfile = power.compute(newSchedule);
    temperatureProfile = hotspot.compute(powerProfile, stepIndex);

    data(i, :) = temperatureProfile(processorIndex, :);
  end
end
