classdef Processor < handle
  properties (SetAccess = private)
    id

    dynamicPower
    executionTime
  end

  methods
    function proc = Processor(id)
      proc.id = id;

      proc.dynamicPower = zeros(0, 0);
      proc.executionTime = zeros(0, 0);
    end

    function addType(proc, power, time)
      proc.dynamicPower(end + 1) = power;
      proc.executionTime(end + 1) = time;
    end

    function count = typeCount(proc)
      count = length(proc.dynamicPower);
    end
  end
end
