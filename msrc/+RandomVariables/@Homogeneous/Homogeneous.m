classdef Homogeneous < RandomVariables.Base
  properties (SetAccess = 'protected')
    distribution
    correlation
  end

  methods
    function this = Homogeneous(dimension, distribution, correlation)
      this = this@RandomVariables.Base(dimension);

      assert(dimension == correlation.dimension, ...
        'The covariance matrix is invalid.');

      this.distribution = distribution;
      this.correlation = correlation;
    end

    function data = invert(this, data)
      data = this.distribution.invert(data);
    end
  end
end
