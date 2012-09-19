classdef Heterogeneous < RandomVariables.Base
  properties (SetAccess = 'protected')
    distributions
    correlation
  end

  methods
    function this = Heterogeneous(dimension, distributions, correlation)
      this = this@RandomVariables.Base(dimension);

      assert(all(dimension == length(distributions)), ...
        'The number of distributions is invalid.');

      assert(dimension == correlation.dimension, ...
        'The covariance matrix is invalid.');

      this.distributions = distributions;
      this.correlation = correlation;
    end

    function data = invert(this, data)
      for i = 1:this.dimension
        data(:, i) = this.distributions{i}.invert(data(:, i));
      end
    end
  end
end
