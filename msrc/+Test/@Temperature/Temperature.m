classdef Temperature < Test.Approximation
  properties (Constant)
    samplingInterval = 1e-4;
    timeDivision = 2;
  end

  properties (SetAccess = 'protected')
    timeSpan
    stepIndex

    power
    hotspot
  end

  methods
    function this = Temperature(varargin)
      this = this@Test.Approximation(varargin{:});
    end
  end

  methods (Access = 'protected')
    configureTestCase(this)
    configureSystem(this)
    configureParameters(this)

    visualizeApproximation(this)

    data = evaluate(this, rvs)
    data = serialize(this)
  end
end
