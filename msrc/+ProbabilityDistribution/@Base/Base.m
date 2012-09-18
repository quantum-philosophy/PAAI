classdef Base < handle
  methods
    function pd = Base()
    end
  end

  methods (Abstract)
    rvs = sample(pd, samples, dimension)
    rvs = invert(pd, rvs)
  end
end
