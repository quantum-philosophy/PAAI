classdef ReducedNormal < Transformation.Normal
  properties
    %
    % The percentage of the variance of the data to preserve.
    %
    threshold
  end

  methods
    function this = ReducedNormal(varargin)
      options = Options(varargin{:});
      this = this@Transformation.Normal(options);

      this.threshold = options.get('threshold', 95);
    end
  end

  methods (Access = 'protected')
    multiplier = computeMultiplier(this, correlation)
  end
end
