classdef Base < handle
  properties (SetAccess = 'protected')
    dimension
    variables
  end

  methods
    function this = Base(rvs)
      this.dimension = rvs.dimension;
      this.variables = rvs;
    end
  end

  methods (Abstract)
    data = sample(this, samples)
  end
end
