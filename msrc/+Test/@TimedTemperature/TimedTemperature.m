classdef TimedTemperature < Test.Temperature
  properties (SetAccess = 'protected')
    timeRange
    tempRange
  end

  methods
    function this = TimedTemperature(varargin)
      this = this@Test.Temperature(varargin{:});
    end
  end

  methods (Access = 'protected')
    configureMethod(this)
    configureParameters(this)

    performApproximation(this)

    data = evaluate(this, rvs)
    data = simulate(this, rvs)
    data = approximate(this, rvs)
  end
end
