classdef Base < handle
  properties (SetAccess = 'protected')
    dimension
  end

  methods
    function up = Base(dimension)
      up.dimension = dimension;
    end
  end

  methods (Abstract)
    rvs = sample(up, samples)
    rvs = invert(up, rvs)
  end
end
