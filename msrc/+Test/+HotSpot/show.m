setup;

samplingInterval = 1e-4; % s

systemFilename = Utils.resolvePath('002_020.tgff');
floorplanFilename = Utils.resolvePath('002.flp', 'test');
configFilename = Utils.resolvePath('hotspot.config');
configLine = sprintf('sampling_intvl %e', samplingInterval);

%% Construct a multiprocessor system running an application.
%
[ platform, application ] = parseTGFF(systemFilename);

%% Schedule the application.
%
schedule = Schedule.Dense(platform, application);

draw(schedule);
display(schedule);

%% Obtain the dynamic power profile.
%
power = PowerProfile(samplingInterval);
powerProfile = power.compute(schedule);

power.display(powerProfile);
power.draw(powerProfile);

%% Compute the corresponding temperature profile.
%
hotspot = HotSpot.Analytic(floorplanFilename, configFilename, configLine);
temperatureProfile = hotspot.compute(powerProfile);

display(hotspot);
hotspot.draw(temperatureProfile);
