function showTemperature()
  setup;

  samplingInterval = 1e-5; % s
  processorCount = 2;
  taskCount = 20;

  %% Configuration.
  %
  [platform, application] = Utils.parseTGFF(Utils.resolvePath( ...
    sprintf('%03d_%03d.tgff', processorCount, taskCount)));

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
  temperature = Test.Configure.temperature( ...
    'samplingInterval', samplingInterval, ...
    'processorCount', processorCount);

  temperatureProfile = temperature.compute(powerProfile);
  temperature.plot(temperatureProfile);
end
