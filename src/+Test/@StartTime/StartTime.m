classdef StartTime < Test.Approximation
  methods
    function this = StartTime(varargin)
      this = this@Test.Approximation(varargin{:});
    end
  end

  methods (Access = 'protected')
    configureParameters(this)

    visualizeApproximation(this)

    data = evaluate(this, rvs)
  end
end
