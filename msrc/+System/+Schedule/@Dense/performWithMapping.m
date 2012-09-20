function performWithMapping(this)
  %
  % Some shortcuts.
  %
  platform = this.platform;
  application = this.application;
  priority = this.priority;

  processorCount = length(platform);
  taskCount = length(application);

  %
  % Obtain roots and sort them according to their priority.
  %
  ids = application.getRoots();
  [ dummy, I ] = sort(priority(ids));
  ids = ids(I);

  pool = application(ids);

  zero = zeros(1, taskCount);

  processed = zero;
  ordered = zero;

  mapping = zero;

  startTime = zero;
  executionTime = zero;

  taskTime = zero;
  processorTime = zeros(1, processorCount);

  position = 0;
  processed(ids) = 1;
  order = zeros;

  while ~isempty(pool)
    %
    % The pool is always sorted according to the priority.
    %
    task = pool{1};

    %
    % Exclude the task.
    %
    pool(1) = [];

    %
    % Append to the schedule.
    %
    position = position + 1;
    order(task.id) = position;
    ordered(task.id) = 1;

    %
    % Find the earliest processor.
    %
    pid = 1;
    earliestTime = processorTime(1);
    for i = 2:processorCount
      if processorTime(i) < earliestTime
        earliestTime = processorTime(i);
        pid = i;
      end
    end

    %
    % Append to the mapping.
    %
    mapping(task.id) = pid;

    startTime(task.id) = max(taskTime(task.id), processorTime(pid));
    executionTime(task.id) = platform{pid}.executionTime(task.type);
    finish = startTime(task.id) + executionTime(task.id);

    processorTime(pid) = finish;

    %
    % Append new tasks that are ready, and ensure that
    % there are no repetitions.
    %
    for i = task.getChildren()
      child = application{i};
      taskTime(child.id) = max(taskTime(child.id), finish);

      %
      % Do not do it twice.
      %
      if processed(child.id), continue; end

      %
      % All the parents should be ordered.
      %
      ready = true;
      for j = child.getParents()
        if ~ordered(application{j}.id)
          ready = false;
          break;
        end
      end

      %
      % Is it ready or should we wait for another parent?
      %
      if ~ready, continue; end

      %
      % We need to insert it in the right place in order
      % to keep the pool sorted by the priority.
      %
      index = 1;
      childPriority = priority(child.id);
      for competitor = pool
        competitor = competitor{1};
        if priority(competitor.id) > childPriority
          break;
        end
        index = index + 1;
      end
      if index > length(pool), pool{end + 1} = child;
      elseif index == 1, pool = { child pool{:} };
      else pool = { pool{1:index - 1} child pool{index:end} };
      end

      %
      % We are done with this one.
      %
      processed(child.id) = 1;
    end
  end

  this.mapping = mapping;
  this.order = order;
  this.startTime = startTime;
  this.executionTime = executionTime;
end
