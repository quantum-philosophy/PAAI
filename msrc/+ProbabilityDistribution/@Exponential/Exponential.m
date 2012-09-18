classdef Exponential < ProbabilityDistribution.Base
  methods
    function pd = Exponential(varargin)
      pd = pd@ProbabilityDistribution.Base(varargin{:});
    end

    function rvs = sample(pd, samples)
      rvs = exprnd(1, samples, pd.dimension);
    end

    function rvs = apply(pd, rvs)
      rvs = expcdf(rvs);
    end

    function rvs = invert(pd, rvs)
      rvs = expinv(rvs);
    end
  end
end
