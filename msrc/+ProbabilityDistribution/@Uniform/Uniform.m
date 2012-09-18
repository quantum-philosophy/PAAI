classdef Uniform < ProbabilityDistribution.Base
  methods
    function pd = Uniform(varargin)
      pd = pd@ProbabilityDistribution.Base(varargin{:});
    end

    function rvs = sample(pd, samples, dimension)
      rvs = rand(samples, dimension);
    end

    function rvs = invert(pd, rvs)
      rvs = unifinv(rvs);
    end
  end
end
