classdef Uniform < ProbabilityTransformation.Base
  properties (SetAccess = 'protected')
    distribution
  end

  methods
    function pt = Uniform(varargin)
      pt = pt@ProbabilityTransformation.Base(varargin{:});
      pt.distribution = ProbabilityDistribution.Uniform();
    end

    function rvs = sample(pt, samples)
      dimension = pt.parameters.dimension;
      rvs = pt.distribution.sample(samples, dimension);
      rvs = pt.parameters.invert(rvs);
    end
  end
end
