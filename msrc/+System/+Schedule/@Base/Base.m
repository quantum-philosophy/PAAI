classdef Base < handle
  properties (SetAccess = 'private')
    platform
    application
  end

  properties (SetAccess = 'protected')
    priority

    mapping
    order

    startTime
    executionTime
  end

  methods
    function this = Base(platform, application, varargin)
      this.platform = platform;
      this.application = application;

      options = Options(varargin{:});

      this.priority = options.get('priority', []);
      this.mapping = options.get('mapping', []);

      this.perform();
    end
  end

  methods (Static, Access = 'protected')
    perform(this)
  end
end
