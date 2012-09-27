classdef SingleNormal < Transformation.Base
  properties (Access = 'private')
    normal
  end

  methods
    function this = SingleNormal(varargin)
      options = Options(varargin{:});
      this = this@Transformation.Base(options);

      this.normal = ProbabilityDistribution.Normal();
    end

    function data = sample(this, samples)
      %
      % Normal RV.
      %
      data = this.normal.sample(samples, 1);

      %
      % The RV with the desired distribution.
      %
      data = this.evaluate(data);
    end

    function data = evaluate(this, data)
      %
      % Uniform RV.
      %
      data = this.normal.apply(data);

      %
      % The RV with the desired distribution.
      %
      data = this.variables.invert(data);
    end
  end
end
