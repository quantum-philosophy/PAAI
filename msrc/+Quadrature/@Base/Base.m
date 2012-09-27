classdef Base < handle
  properties (SetAccess = 'private')
    %
    % Integration nodes.
    %
    nodes

    %
    % Integration weights.
    %
    weights
  end

  methods
    function this = Base(varargin)
      options = Options('method', 'tensor', varargin{:});
      this.initialize(options);
    end

    function result = integrate(this, f)
      values = eval(f, this.nodes);
      codimension = size(values, 1);
      result = sum(repmat(this.weights, codimension, 1) .* values, 2);
    end
  end

  methods (Access = 'protected')
    [ nodes, weights ] = construct(this, dimension, level)

    function initialize(this, options)
      filename = [ class(this), '_', string(options), '.mat' ];
      filename = Utils.resolvePath(filename, 'cache');

      if exist(filename, 'file')
        load(filename);
      else
        switch lower(options.method)
        case 'tensor'
          [ nodes, weights ] = this.constructTensorProduct( ...
            options.dimension, options.level);
        case 'sparse'
          [ nodes, weights ] = this.constructSparseGrid( ...
            options.dimension, options.level);
        otherwise
          error('The quadrature type is unknown.');
        end
        save(filename, 'nodes', 'weights', '-v7.3');
      end

      this.nodes = nodes;
      this.weights = weights;
    end

    function [ Nodes, Weights ] = constructTensorProduct(this, dimension, level)
      [ nodes, weights ] = this.construct(1, level);
      nodes = transpose(nodes);
      weights = transpose(weights);

      Nodes = {};
      Weights = {};

      for i = 1:dimension
        Nodes{end + 1} = nodes;
        Weights{end + 1} = weights;
      end

      [ Nodes, Weights ] = tensor_product(Nodes, Weights);

      Nodes = transpose(Nodes);
      Weights = transpose(Weights);
    end

    function [ nodes, weights ] = constructSparseGrid(this, dimension, level)
      [ nodes, weights ] = this.construct(dimension, level);
    end
  end
end
