function configureSystem(this)
  [ this.platform, this.application ] = parseTGFF(Utils.resolvePath( ...
    sprintf('%03d_%03d.tgff', this.processorCount, this.taskCount)));

  this.schedule = Schedule.Dense(this.platform, this.application);
end
