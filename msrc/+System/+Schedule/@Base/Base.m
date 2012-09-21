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

      nan = ones(length(application), 1) * NaN;

      this.priority = options.get('priority', nan);

      this.mapping = options.get('mapping', nan);
      this.order = nan;

      this.executionTime = options.get('executionTime', nan);
      this.startTime = nan;

      this.perform();
    end
  end

  methods (Static, Access = 'protected')
    perform(this)
  end
end
