classdef htASGC < handle
  properties (SetAccess = 'protected')
    inputCount
    outputCount
    agentCount

    samplingInterval

    level
    nodeCount
    levelNodeCount

    levelIndex
    startIndex
    finishIndex

    nodes
    surpluses

    expectation
    variance
  end

  methods
    function this = htASGC(f, varargin)
      options = Options(varargin{:});
      this.construct(f, options);
    end
  end

  methods (Access = 'protected')
    construct(this, f, options)
  end
end
