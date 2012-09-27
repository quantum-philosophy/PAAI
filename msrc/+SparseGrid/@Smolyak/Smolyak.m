classdef Smolyak < SparseGrid.Base
  methods
    function this = Smolyak(varargin)
      this = this@SparseGrid.Base(varargin{:});
    end
  end

  methods (Access = 'protected')
    [ nodes, weights ] = construct(this, options);
  end
end
