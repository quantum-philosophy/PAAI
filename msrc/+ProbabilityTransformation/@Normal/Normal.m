classdef Normal < ProbabilityTransformation.Base
  properties (SetAccess = 'protected')
    normal
  end

  properties (Access = 'protected')
    R
  end

  methods
    function pt = Normal(varargin)
      pt = pt@ProbabilityTransformation.Base(varargin{:});

      pt.normal = ProbabilityDistribution.Normal(pt.parameters.dimension);

      switch class(pt.parameters.correlation)
      case 'Correlation.Spearman'
        Cp = Correlation.convertSpearmanToPearson( ...
          pt.parameters.correlation.matrix);
      otherwise
        error('The correlation matrix is not supported.');
      end

      pt.R = chol(Cp);
    end

    function rvs = generate(pt, samples)
      rvs = pt.normal.sample(samples);
    end

    function rvs = apply(pt, rvs)
      %
      % Given independent standard normal RVs.
      %

      %
      % Dependent normal RVs.
      %
      rvs = rvs * pt.R;

      %
      % Dependent uniform RVs.
      %
      rvs = pt.normal.apply(rvs);

      %
      % Dependent RVs with the desired marginal distributions.
      %
      rvs = pt.parameters.invert(rvs);
    end
  end
end
