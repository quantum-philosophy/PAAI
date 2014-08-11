function configureSystem(this)
  configureSystem@Test.Approximation(this);

  floorplan = Utils.resolvePath( ...
    sprintf('%03d.flp', this.processorCount), 'test');
  hotspotConfig = Utils.resolvePath( ...
    'hotspot.config', 'test');
  hotspotLine = sprintf('sampling_intvl %e', ...
    this.samplingInterval);

  this.power = DynamicPower(this.samplingInterval);
  this.hotspot = HotSpot.Analytic(floorplan, hotspotConfig, hotspotLine);
end
