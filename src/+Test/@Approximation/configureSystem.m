function configureSystem(this)
  [this.platform, this.application] = Utils.parseTGFF(Utils.resolvePath( ...
    sprintf('%03d_%03d.tgff', this.processorCount, this.taskCount)));

  this.scheduler = Scheduler.Dense( ...
    'platform', this.platform, 'application', this.application);

  this.schedule = this.scheduler.decode(this.scheduler.compute());
end
