classdef Base < handle
  properties (SetAccess = 'private')
    dimension
    points
    nodes
    weights
  end

  methods
    function this = Base(varargin)
      options = Options(varargin{:});
      this.initialize(options);
    end
  end

  methods (Abstract, Access = 'protected')
    [ nodes, weights ] = construct(this, options)
  end

  methods (Access = 'private')
    function initialize(this, options)
      this.dimension = options.dimension;
      [ this.nodes, this.weights ] = this.construct(options);
      this.points = length(this.weights);
    end
  end
end
