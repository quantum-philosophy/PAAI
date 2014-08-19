classdef TemporalApproximation < Test.Approximation
  properties (Constant)
    samplingInterval = 1e-3;
    timeDivision = 1;
  end

  properties (SetAccess = 'protected')
    timeSpan
    stepIndex
  end

  methods
    function this = TemporalApproximation(varargin)
      this = this@Test.Approximation(varargin{:});
    end
  end

  methods (Access = 'protected')
    configureTestCase(this)
    configureParameters(this)

    visualizeApproximation(this)

    data = serialize(this)
  end
end
