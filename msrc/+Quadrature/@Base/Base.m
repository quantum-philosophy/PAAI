classdef Base < handle
  properties (SetAccess = 'private')
    dimension
    level
    rules

    points
    nodes
    weights
  end

  methods
    function this = Base(varargin)
      options = Options(varargin{:});
      this.initialize(options);
    end

    function result = integrate(this, f)
      values = eval(f, this.nodes);
      codimension = size(values, 1);
      result = sum(repmat(this.weights, codimension, 1) .* values, 2);
    end
  end

  methods (Abstract, Access = 'protected')
    [ nodes, weights ] = construct(this, options)
  end

  methods (Access = 'private')
    function initialize(this, options)
      this.dimension = options.dimension;
      this.level = options.level;
      this.rules = options.rules;

      filename = [ class(this), '_', string(options), '.mat' ];
      filename = Utils.resolvePath(filename, 'cache');

      if exist(filename, 'file')
        load(filename);
      else
        [ nodes, weights ] = this.construct(options);
        save(filename, 'nodes', 'weights', '-v7.3');
      end

      this.points = length(weights);
      this.nodes = nodes;
      this.weights = weights;
    end
  end
end
