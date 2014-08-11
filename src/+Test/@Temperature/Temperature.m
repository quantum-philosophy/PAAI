classdef Temperature < Test.TemporalApproximation
  properties (SetAccess = 'protected')
    power
    hotspot
  end

  methods
    function this = Temperature(varargin)
      this = this@Test.TemporalApproximation(varargin{:});
    end
  end

  methods (Access = 'protected')
    configureSystem(this)
    data = evaluate(this, rvs)
  end
end
