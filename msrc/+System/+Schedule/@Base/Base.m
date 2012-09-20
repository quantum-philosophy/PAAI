classdef Base < handle
  properties (SetAccess = 'private')
    platform
    application

    priority
  end

  properties (SetAccess = 'protected')
    mapping
    order

    startTime
    executionTime
  end

  methods
    function this = Base(platform, application)
      this.platform = platform;
      this.application = application;

      this.perform();
    end
  end

  methods (Static, Access = 'protected')
    performWithMapping(this)
  end

  methods (Access = 'private')
    function perform(this)
      %
      % Find priorities of the tasks.
      %
      profile = System.Profile.Average(this.platform, this.application);
      this.priority = profile.taskMobility;

      %
      % Now, the order, mapping, start and execution times.
      %
      this.performWithMapping();
    end
  end
end
