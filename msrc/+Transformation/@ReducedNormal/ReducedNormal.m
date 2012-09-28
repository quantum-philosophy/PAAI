classdef ReducedNormal < Transformation.Normal
  properties
    %
    % The percentage of the variance of the data to preserve.
    %
    threshold
  end

  methods
    function this = ReducedNormal(varargin)
      this = this@Transformation.Normal(varargin{:});
    end
  end

  methods (Access = 'protected')
    multiplier = computeMultiplier(this, correlation)

    function initialize(this, variable, options)
      this.threshold = options.get('threshold', 95);
      initialize@Transformation.Normal(this, variable, options);
    end
  end
end
