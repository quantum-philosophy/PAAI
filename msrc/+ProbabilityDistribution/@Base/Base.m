classdef Base < handle
  properties (SetAccess = 'private')
    dimension
  end

  methods
    function pd = Base(dimension)
      if nargin < 1, dimension = 1; end

      assert(dimension > 0, 'The dimension is invalid.');

      pd.dimension = dimension;
    end
  end

  methods (Abstract)
    rvs = sample(pd, samples)
    rvs = apply(pd, rvs)
    rvs = invert(pd, rvs)
  end
end
