classdef Nataf < Transformation.Base
  properties
    quadratureOptions = Options( ...
      'dimension', 2, ...
      'level', 5, ...
      'method', 'tensor');

    optimizationOptions = optimset( ...
      'TolX', 1e-6);
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
      this.normal = ProbabilityDistribution.Normal();
      this.correlation = this.computeCorrelation(this.variables);
      this.R = chol(this.correlation.matrix);
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
