classdef Hermite < PolynomialChaos.Base
  methods
    function pc = Hermite(varargin)
      pc = pc@PolynomialChaos.Base(varargin{:});
    end
  end

  methods (Access = 'protected')
    function method = prepare(pc, method)
      method = Utils.merge(struct( ...
        'chaosType', 'TotalOrder', ...
        'quadratureName', 'GaussHermite', ...
        'quadratureType', 'Adaptive'), method);

      method.chaosName = 'Hermite';
    end

    function psi = construct1D(pc, x, order)
      psi(1) = sympoly(1);

      for i = 2:(order + 1)
        psi(i) = x * psi(i - 1) - diff(psi(i - 1), x);
      end
    end
  end
end
