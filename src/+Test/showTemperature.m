function showTemperature()
  setup;

  samplingInterval = 1e-3; % s
  processorCount = 2;
  taskCount = 20;

  %% Configuration.
  %
  [platform, application] = Utils.parseTGFF(Utils.resolvePath( ...
    sprintf('%03d_%03d.tgff', processorCount, taskCount)));

  floorplan = Utils.resolvePath(sprintf('%03d.flp', processorCount));
  hotspotConfig = Utils.resolvePath('hotspot.config');
  hotspotLine = [ ...
    sprintf(' t_chip %e', 0.00015), ... 0.00015
    sprintf(' k_chip %e', 100.0  ), ... 100.0
    sprintf(' p_chip %e', 1.75e6 ), ... 1.75e6
    ...
    sprintf(' t_interface %e', 2.0e-05), ... 2.0e-05
    sprintf(' k_interface %e', 4.0    ), ... 4.0
    sprintf(' p_interface %e', 4.0e6  ), ... 4.0e6
    ...
    sprintf(' s_sink %e', 0.06  ), ... 0.06
    sprintf(' t_sink %e', 0.0069), ... 0.0069
    sprintf(' k_sink %e', 400.0 ), ... 400.0
    sprintf(' p_sink %e', 3.55e6), ... 3.55e6
    ...
    sprintf(' s_spreader %e', 0.03  ), ... 0.03
    sprintf(' t_spreader %e', 0.001 ), ... 0.001
    sprintf(' k_spreader %e', 400.0 ), ... 400.0
    sprintf(' p_spreader %e', 3.55e6), ... 3.55e6
    ...
    sprintf(' sampling_intvl %e', samplingInterval) ...
  ];

  %% Schedule the application.
  %
  scheduler = Scheduler.Dense('platform', platform, 'application', application);
  schedule = scheduler.compute();

  scheduler.plot(schedule);
  scheduler.display(schedule);

  %% Obtain the dynamic power profile.
  %
  power = DynamicPower('platform', platform, 'application', application, ...
    'samplingInterval', samplingInterval);
  powerProfile = power.compute(schedule);

  power.display(powerProfile);
  power.plot(powerProfile);

  %% Compute the corresponding temperature profile.
  %
  temperature = Temperature.Analytical.Transient( ...
    'floorplan', floorplan, ...
    'hotspotConfig', hotspotConfig, ...
    'hotspotLine', hotspotLine, ...
    'samplingInterval', samplingInterval, ...
    'processorCount', processorCount);

  temperatureProfile = temperature.compute(powerProfile);
  temperature.plot(temperatureProfile);
end
