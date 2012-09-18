classdef Base < handle
  properties (SetAccess = 'protected')
    dimension
    matrix
  end

  methods
    function cr = Base(dimension)
      cr.dimension = dimension;
    end
  end

  methods (Abstract)
  end
end
