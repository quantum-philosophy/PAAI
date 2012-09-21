classdef GaussHermite < Quadrature.Base
  methods
    function this = GaussHermite(varargin);
      this = this@Quadrature.Base(varargin{:});
    end

    function norm = computeNormalizationConstant(this, i, index)
      norm = prod(factorial(index(i, :) - 1));
    end
  end

  methods (Access = 'protected')
    function [ nodes, weights ] = construct(this, dimension, level)
      [ nodes, weights ] = nwspgr('gqn', dimension, level);
      nodes = transpose(nodes);
      weights = transpose(weights);
    end
  end
end
