function data = evaluate(this, rvs)
  taskIndex = this.taskIndex;
  schedule = this.schedule;

  rvs = this.transformation.evaluate(rvs);
  pointCount = size(rvs, 1);
  data = zeros(pointCount, this.outputDimension);

  newExecutionTime = schedule.executionTime;
  for i = 1:pointCount
    newExecutionTime(taskIndex) = schedule.executionTime(taskIndex) + rvs(i, :);
    newSchedule = Schedule.Dense(schedule, 'executionTime', newExecutionTime);
    data(i, :) = newSchedule.startTime;
  end
end
