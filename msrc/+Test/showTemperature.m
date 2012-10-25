setup;

samplingInterval = 1e-4; % s
processorCount = 2;
taskCount = 20;

%% Configuration.
%
[ platform, application ] = parseTGFF(Utils.resolvePath( ...
sprintf('%03d_%03d.tgff', processorCount, taskCount)));

floorplan = Utils.resolvePath( ...
sprintf('%03d.flp', processorCount), 'test');
hotspotConfig = Utils.resolvePath( ...
  'hotspot.config', 'test');
hotspotLine = sprintf('sampling_intvl %e', ...
  samplingInterval);

%% Schedule the application.
%
schedule = Schedule.Dense(platform, application);

plot(schedule);
display(schedule);

%% Obtain the dynamic power profile.
%
power = PowerProfile(samplingInterval);
powerProfile = power.compute(schedule);

power.display(powerProfile);
power.plot(powerProfile);

%% Compute the corresponding temperature profile.
%
hotspot = HotSpot.Analytic(floorplan, hotspotConfig, hotspotLine);
temperatureProfile = hotspot.compute(powerProfile);

display(hotspot);
hotspot.plot(temperatureProfile);

stepCount = size(temperatureProfile, 2);
csvwrite('dump.csv', [ (1:stepCount).' temperatureProfile.' ]);