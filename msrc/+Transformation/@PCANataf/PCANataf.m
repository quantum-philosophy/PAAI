classdef PCANataf < Transformation.Nataf
  properties
    %
    % The percentage of the variance of the data to preserve.
    %
    threshold
  end

  methods
    function this = PCANataf(varargin)
      options = Options(varargin{:});
      this = this@Transformation.Nataf(options);

      this.threshold = options.get('threshold', 95);
    end
  end

  methods (Access = 'protected')
    multiplier = computeMultiplier(this, correlation)
  end
end
