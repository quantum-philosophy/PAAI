classdef Exponential < ProbabilityDistribution.Base
  methods
    function pd = Exponential(varargin)
      pd = pd@ProbabilityDistribution.Base(varargin{:});
    end

    function rvs = sample(pd, samples, dimension)
      rvs = exprnd(1, samples, dimension);
    end

    function rvs = invert(pd, rvs)
      rvs = expinv(rvs);
    end
  end
end
