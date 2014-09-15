function data = evaluate(this, rvs)
  processorIndex = this.processorIndex;
  taskIndex = this.taskIndex;
  stepIndex = this.stepIndex;

  power = this.power;
  temperature = this.temperature;

  scheduler = this.scheduler;
  schedule = this.schedule;
  arguments = { schedule.mapping, schedule.priority, schedule.order, [] };

  rvs = this.transformation.evaluate(rvs);
  pointCount = size(rvs, 1);
  data = zeros(pointCount, this.outputCount);

  for i = 1:pointCount
    newExecutionTime = schedule.executionTime;
    newExecutionTime(taskIndex) = ...
      schedule.executionTime(taskIndex) + rvs(i, :);
    newSchedule = scheduler.compute(arguments{:}, newExecutionTime);

    powerProfile = power.compute(newSchedule);
    temperatureProfile = temperature.compute(powerProfile);

    data(i, :) = temperatureProfile(processorIndex, stepIndex);
  end
end
