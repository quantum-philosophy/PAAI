classdef Normal < ProbabilityDistribution.Base
  methods
    function this = Normal(varargin)
      this = this@ProbabilityDistribution.Base(varargin{:});
    end

    function data = sample(this, samples, dimension)
      data = randn(samples, dimension);
    end

    function data = apply(this, data)
      rvs = normcdf(data);
    end

    function data = invert(this, data)
      data = norminv(data);
    end
  end
end
