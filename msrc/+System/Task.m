classdef Task < handle
  properties (SetAccess = private)
    id
    type

    isLeaf
    isRoot

    parents
    children
  end

  methods
    function task = Task(id, type)
      task.id = id;
      task.type = type;

      task.isLeaf = true;
      task.isRoot = true;

      task.parents = {};
      task.children = {};
    end

    function addParent(task, parent)
      task.parents{end + 1} = parent;
      task.isRoot = false;
    end

    function addChild(task, child)
      task.children{end + 1} = child;
      task.isLeaf = false;
    end
  end
end
