classdef Normal < ProbabilityDistribution.Base
  methods
    function pd = Normal(varargin)
      pd = pd@ProbabilityDistribution.Base(varargin{:});
    end

    function rvs = sample(pd, samples)
      rvs = randn(samples, pd.dimension);
    end

    function rvs = apply(pd, rvs)
      rvs = normcdf(rvs);
    end

    function rvs = invert(pd, rvs)
      rvs = norminv(rvs);
    end
  end
end
