classdef TemporalApproximation < Test.Approximation
  properties (Constant)
    samplingInterval = 1e-4;
    timeDivision = 2;
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
