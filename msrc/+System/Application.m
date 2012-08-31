classdef Application < handle
  properties (SetAccess = 'private')
    tasks
  end

  properties (Access = 'private')
    taskMap
  end

  methods
    function app = Application()
      app.tasks = {};
      app.taskMap = containers.Map();
    end

    function task = addTask(app, name, type)
      id = app.taskCount + 1;
      task = System.Task(id, type);
      app.tasks{end + 1} = task;
      app.taskMap(name) = task;
    end

    function addLink(app, parent, child)
      parent = app.taskMap(parent);
      child = app.taskMap(child);
      parent.addChild(child);
      child.addParent(parent);
    end

    function count = taskCount(app)
      count = length(app.tasks);
    end

    function display(app)
      fprintf('Application:\n');
      fprintf('  Number of tasks: %d\n', app.taskCount);

      fprintf('  Data dependencies:\n');
      fprintf('    %4s ( %4s ) -> [ %s ]\n', 'id', 'type', 'children');

      for i = 1:app.taskCount
        task = app.tasks{i};
        fprintf('    %4d ( %4d ) -> [ ', task.id, task.type);
        for j = 1:length(task.children)
          child = task.children{j};
          if j > 1, fprintf(', '); end
          fprintf('%d', child.id);
        end
        fprintf(' ]\n');
      end
    end
  end
end
