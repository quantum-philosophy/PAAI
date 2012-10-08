setup;

samples = 1e3;
samplingInterval = 1e-4; % s

floorplanFilename = Utils.resolvePath('002.flp', 'test');
configFilename = Utils.resolvePath('hotspot.config');
configLine = sprintf('sampling_intvl %e', samplingInterval);

[ platform, application, schedule, parameters ] = ...
  Test.Case.constructBeta('002_020');

%% Perform the probability transformation.
%
transformation = ProbabilityTransformation.Normal(parameters);

%% Initialize the power computation.
%
power = PowerProfile(samplingInterval);

%% Initialize the temperature simulator.
%
hotspot = HotSpot.Analytic(floorplanFilename, configFilename, configLine);

processorCount = length(platform);
executionTime = schedule.executionTime;

filename = sprintf('HotSpot_simulateMaximum_samples_%d.mat', samples);

if File.exist(filename)
  load(filename);
else
  data = zeros(samples, processorCount);

  progress = Bar('Monte Carlo simulation: %d out of %d.', samples);

  tic;
  for i = 1:samples
    schedule.adjustExecutionTime( ...
      executionTime + transformation.sample(1));

    powerProfile = power.compute(schedule);
    temperatureProfile = hotspot.compute(powerProfile);

    data(i, :) = max(temperatureProfile, [], 2).';

    progress.increase();
  end
  time = toc;

  save(filename, 'data', 'time', '-v7.3');
end

fprintf('Monte Carlo:\n');
fprintf('  Samples: %d\n', samples);
fprintf('  Simulation time: %.2f s\n', time);

data = convertKelvinToCelsius(data);

for i = 1:processorCount
  observeData(data(:, i), ...
    'draw', 'true', 'method', 'histogram', 'range', 'unbounded');
  title([ 'Maximal temperature of Core ', num2str(i) ]);
  xlabel('Temperature, C');
  ylabel('Empirical PDF');
end
