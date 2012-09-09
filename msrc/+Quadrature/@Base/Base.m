classdef Base < handle
  properties (SetAccess = 'private')
    %
    % Precomputed value of each of the polynomials in the PC expansion in
    % each of the points of the sparse grid multiplied by the corresponding
    % weight and divided by the corresponding normalization constant.
    %
    grid

    %
    % The normalization constants of the expansion, i.e., <psi_i^2>.
    %
    norm
  end

  properties (SetAccess = 'private')
    %
    % The evaluation points for the integration.
    %
    nodes

    %
    % The number of points.
    %
    points
  end

  methods
    function qd = Base(x, psi, index, method)
      method = qd.prepare(method);

      [ qd.nodes, qd.grid, qd.norm ] = qd.precomputeGrid(x, psi, index, method);
      qd.points = size(qd.nodes, 2);
    end
  end

  methods (Abstract, Access = 'protected')
    [ nodes, weights ] = construct1D(qd, order);
    [ nodes, weights, points ] = constructSparseGrid(qd, sdim, order);
    norm = computeNormalizationConstant(qd, i, index);
  end

  methods (Static, Abstract)
    points = countSparseGridPoints(qd, sdim, order);
  end

  methods (Access = 'protected')
    [ nodes, weights, points ] = constructTensorProduct(qd, sdim, order);
    [ nodes, grid, norm ] = doPrecomputeGrid(qd, x, psi, order, index, method)

    function method = prepare(qd, method)
      if ~isfield(method, 'quadratureOrder') || isempty(method.quadratureOrder)
        %
        % The order of a Gaussian quadrature rule, denoted by `order', means that
        % the rule is exact for (2 * `order' - 1)-order polynomials. We want to have
        % exactness for polynomials of order (2 * `order'), therefore, the rule order
        % should be increased by one.
        %
        method.quadratureOrder = method.chaosOrder + 1;
      end
      if ~isfield(method, 'quadratureLevel') || isempty(method.quadratureLevel)
        %
        %   order = 2^(level + 1) - 1
        %   level = log2(order + 1) - 1
        %
        method.quadratureLevel = ceil(log2(method.quadratureOrder + 1) - 1);
      end
    end

    function [ nodes, grid, norm ] = finalize(qd, sdim, nodes, grid, norm)
    end

    function [ nodes, grid, norm ] = precomputeGrid(qd, x, psi, index, method)
      sdim = length(x);
      terms = length(psi);

      filename = [ Quadrature.methodStamp(method), ...
        '_sd', num2str(sdim), '_pt', num2str(terms), '.mat' ];

      filename = Utils.resolvePath(filename, 'cache');

      if exist(filename, 'file')
        load(filename);
      else
        [ nodes, grid, norm ] = qd.doPrecomputeGrid(x, psi, index, method);
        save(filename, 'nodes', 'grid', 'norm', '-v7.3');
      end
    end
  end

  methods (Static)
    function points = countTensorProductPoints(sdim, order)
      points = order^sdim;
    end
  end
end
