function data = evaluate(this, rvs)
  taskIndex = this.taskIndex;

  schedule = this.schedule;
  scheduler = this.scheduler;
  arguments = { schedule.mapping, schedule.priority, schedule.order, [] };

  rvs = this.transformation.evaluate(rvs);
  pointCount = size(rvs, 1);
  data = zeros(pointCount, this.outputCount);

  newExecutionTime = schedule.executionTime;
  for i = 1:pointCount
    newExecutionTime(taskIndex) = schedule.executionTime(taskIndex) + rvs(i, :);
    newSchedule = scheduler.decode(scheduler.compute( ...
      arguments{:}, newExecutionTime));
    data(i, :) = newSchedule.startTime;
  end
end
