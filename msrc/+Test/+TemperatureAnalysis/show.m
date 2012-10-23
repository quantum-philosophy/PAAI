setup;

samplingInterval = 1e-4; % s

%% Configuration.
%
[ platform, application, floorplan, hotspotConfig, hotspotLine ] = ...
  Test.Case.request('samplingInterval', samplingInterval, 'silent', true);

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
