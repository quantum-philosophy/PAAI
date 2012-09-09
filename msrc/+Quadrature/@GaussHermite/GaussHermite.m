classdef GaussHermite < Quadrature.Base
  methods
    function qd = GaussHermite(varargin);
      qd = qd@Quadrature.Base(varargin{:});
    end
  end

  methods (Access = 'protected')
    function [ nodes, weights ] = construct1D(qd, order)
      [ nodes, weights ] = nwspgr('gqn', 1, order);
    end

    function [ nodes, weights, points ] = constructSparseGrid(qd, sdim, order, level);
      [ nodes, weights ] = nwspgr('gqn', sdim, order);
      nodes = transpose(nodes);
      weights = transpose(weights);
      points = size(weights, 2);
    end

    function norm = computeNormalizationConstant(qd, i, index)
      norm = prod(factorial(index(i, :) - 1));
    end
  end

  methods (Static)
    function points = countSparseGridPoints(sdim, order, level)
      [ ~, weights ] = nwspgr('gqn', sdim, order);
      points = length(weights);
    end
  end
end
