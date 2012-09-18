classdef Uniform < ProbabilityDistribution.Base
  methods
    function pd = Uniform(varargin)
      pd = pd@ProbabilityDistribution.Base(varargin{:});
    end

    function rvs = sample(pd, samples)
      rvs = rand(samples, pd.dimension);
    end

    function rvs = apply(pd, rvs)
      rvs = unifcdf(rvs);
    end

    function rvs = invert(pd, rvs)
      rvs = unifinv(rvs);
    end
  end
end
