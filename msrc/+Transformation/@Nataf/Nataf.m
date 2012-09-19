classdef Nataf < Transformation.Base
  properties
    quadratureLevel = 4
  end

  properties (SetAccess = 'private')
    correlation
  end

  properties (Access = 'private')
    normal
    R
  end

  methods
    function this = Nataf(varargin)
      this = this@Transformation.Base(varargin{:});
      this.correlation = this.computeCorrelation(this.variables);
      this.R = chol(this.correlation.matrix);
      this.normal = ProbabilityDistribution.Normal();
    end

    function data = sample(this, samples)
      %
      % Independent normal RVs.
      %
      data = this.normal.sample(samples, this.dimension);

      %
      % Dependent normal RVs.
      %
      data = data * this.R;

      %
      % Dependent uniform RVs.
      %
      data = this.normal.apply(data);

      %
      % Dependent RVs with the desired distributions.
      %
      data = this.variables.invert(data);
    end
  end

  methods (Access = 'private')
    correlation = computeCorrelation(this, rvs)
  end
end
