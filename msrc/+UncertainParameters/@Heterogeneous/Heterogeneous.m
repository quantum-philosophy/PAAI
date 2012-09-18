classdef Heterogeneous < UncertainParameters.Base
  properties (SetAccess = 'protected')
    distributions
    correlation
    transformation
  end

  methods
    function up = Heterogeneous(distributions, correlation)
      up = up@UncertainParameters.Base(numel(distributions));

      assert(all(correlation.dimension == up.dimension), ...
        'The size of the correlation matrix is invalid.');

      up.distributions = distributions;
      up.correlation = correlation;

      up.transformation = ProbabilityTransformation.Normal(up);
    end

    function rvs = sample(up, samples)
      rvs = up.transformation.sample(samples);
    end

    function rvs = invert(up, rvs)
      for i = 1:up.dimension
        rvs(:, i) = up.distributions{i}.invert(rvs(:, i));
      end
    end
  end
end
