classdef Normal < ProbabilityDistribution.Base
  methods
    function this = Normal()
      this = this@ProbabilityDistribution.Base();
    end

    function data = sample(this, samples, dimension)
      data = randn(samples, dimension);
    end

    function data = apply(this, data)
      data = normcdf(data);
    end

    function data = invert(this, data)
      data = norminv(data);
    end
  end
end
