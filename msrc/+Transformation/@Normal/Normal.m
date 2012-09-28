classdef Normal < Transformation.Base
  properties
    %
    % Configuration of the numerical integration procedure
    % used to match the correlation coefficients.
    %
    quadratureOptions

    %
    % Configuration of the numerical root finding procedure
    % used to match the correlation coefficients.
    %
    optimizationOptions
  end

  properties (Access = 'private')
    normal
  end

  properties (SetAccess = 'private')
    %
    % The correlation matrix as produced by the pure probability
    % transformation.
    %
    correlation

    %
    % The corresponding multiplier produced by some decomposition
    % procedure used to construct RVs with the obtained or approximated
    % correlation matrix.
    %
    multiplier

    %
    % The number of dimensions left after the decomposition.
    %
    reducedDimension
  end

  methods
    function this = Normal(varargin)
      this = this@Transformation.Base(varargin{:});
    end

    function data = sample(this, samples)
      %
      % Independent normal RVs.
      %
      data = this.normal.sample(samples, this.reducedDimension);

      %
      % Dependent normal RVs.
      %
      data = data * this.multiplier;

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

  methods (Access = 'protected')
    multiplier = computeMultiplier(this, correlation)

    function initialize(this, variables, options)
      initialize@Transformation.Base(this, variables, options);

      this.quadratureOptions = options.get('quadratureOptions', ...
        Options('dimension', 2, 'level', 5));
      this.optimizationOptions = options.get('optimizationOptions', ...
        optimset('TolX', 1e-6));

      this.normal = ProbabilityDistribution.Normal();

      this.correlation = this.computeCorrelation(variables);
      this.multiplier = this.computeMultiplier(this.correlation);

      this.reducedDimension = size(this.multiplier, 1);
    end
  end
end
