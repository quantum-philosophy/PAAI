classdef Power < Test.TemporalApproximation
  properties (SetAccess = 'protected')
    power
  end

  methods
    function this = Power(varargin)
      this = this@Test.TemporalApproximation(varargin{:});
    end
  end

  methods (Access = 'protected')
    configureSystem(this)

    data = evaluate(this, rvs)
  end
end
