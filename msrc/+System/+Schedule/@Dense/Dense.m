classdef Dense < System.Schedule.Base
  methods
    function this = Dense(varargin)
      this = this@System.Schedule.Base(varargin{:});
    end
  end

  methods (Access = 'protected')
    performWithMapping(this)
  end
end
