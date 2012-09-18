classdef Uniform < ProbabilityTransformation.Normal
  properties (SetAccess = 'protected')
    uniform
  end

  methods
    function pt = Uniform(varargin)
      pt = pt@ProbabilityTransformation.Normal(varargin{:});

      pt.uniform = ProbabilityDistribution.Uniform(pt.parameters.dimension);
    end

    function rvs = generate(pt, samples)
      rvs = pt.uniform.sample(samples);
    end

    function rvs = apply(pt, rvs)
      %
      % Given independent standard uniform RVs.
      %

      %
      % Independent normal RVs.
      %
      rvs = pt.normal.invert(rvs);

      %
      % Dependent RVs with the desired marginal distributions.
      %
      rvs = apply@ProbabilityTransformation.Normal(pt, rvs);
    end
  end
end
