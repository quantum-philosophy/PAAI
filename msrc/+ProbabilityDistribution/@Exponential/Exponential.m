classdef Exponential < ProbabilityDistribution.Base
  methods
    function this = Exponential(varargin)
      this = this@ProbabilityDistribution.Base(varargin{:});
    end

    function data = sample(this, samples, dimension)
      data = exprnd(1, samples, dimension);
    end

    function data = apply(this, data)
      data = expcdf(data);
    end

    function data = invert(this, data)
      data = expinv(data);
    end
  end
end
