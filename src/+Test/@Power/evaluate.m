function data = evaluate(this, rvs)
  processorIndex = this.processorIndex;
  taskIndex = this.taskIndex;

  power = this.power;

  scheduler = this.scheduler;
  schedule = this.schedule;
  arguments = { schedule.mapping, schedule.priority, schedule.order, [] };

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

    data(i, :) = powerProfile(processorIndex, :);
  end
end
