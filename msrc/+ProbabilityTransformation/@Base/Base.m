classdef Base < handle
  properties (SetAccess = 'protected')
    parameters
  end

  methods
    function pt = Base(up)
      pt.parameters = up;
    end
  end

  methods (Abstract)
    rvs = sample(pt, samples)
  end
end
