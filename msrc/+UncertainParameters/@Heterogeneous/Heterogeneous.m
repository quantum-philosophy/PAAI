classdef Heterogeneous < UncertainParameters.Base
  properties (SetAccess = 'protected')
    distributions
    correlation
  end

  methods
    function up = Heterogeneous(distributions, correlation)
      up = up@UncertainParameters.Base(numel(distributions));

      assert(all(correlation.dimension == up.dimension), ...
        'The size of the correlation matrix is invalid.');

      up.distributions = distributions;
      up.correlation = correlation;
    end

    function rvs = sample(up, samples)
      rvs = zeros(samples, up.dimension);
      for i = 1:up.dimension
        rvs(:, i) = up.distributions{i}.sample(samples, 1);
      end
    end

    function rvs = invert(up, rvs)
      for i = 1:up.dimension
        rvs(:, i) = up.distributions{i}.invert(rvs(:, i));
      end
    end
  end
end
