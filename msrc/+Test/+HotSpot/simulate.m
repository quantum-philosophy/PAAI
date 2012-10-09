setup;
includeLibrary('Vendor/DataHash');

sampleCount = 1e3;
samplingInterval = 1e-4; % s

%% Select what we want to observe.
%
timeMoment = 0.1;
timeStep = floor(timeMoment / samplingInterval);

taskIndex = 1;

%% Configuration files.
%
floorplanFilename = Utils.resolvePath('002.flp', 'test');
configFilename = Utils.resolvePath('hotspot.config');
configLine = sprintf('sampling_intvl %e', samplingInterval);

[ platform, application, schedule, parameters ] = ...
  Test.Case.constructBeta('002_020', taskIndex);

%% Perform the probability transformation.
%
transformation = ProbabilityTransformation.Normal(parameters);

dimensionCount = transformation.dimension;

%% Initialize the power computation.
%
power = PowerProfile(samplingInterval);

%% Initialize the temperature simulator.
%
hotspot = HotSpot.Analytic(floorplanFilename, configFilename, configLine);

processorCount = length(platform);
taskCount = length(application);
executionTime = schedule.executionTime;

maxStepCount = 1.5 * duration(schedule) / samplingInterval;

filename = sprintf('HotSpot_simulate_%s.mat', ...
  DataHash({ taskIndex, samplingInterval, sampleCount }));

if File.exist(filename)
  load(filename);
else
  data = zeros(sampleCount, processorCount, maxStepCount);
  samples = zeros(sampleCount, dimensionCount);
  addition = zeros(1, taskCount);

  progress = Bar('Monte Carlo simulation: %d out of %d.', sampleCount);

  tic;
  for i = 1:sampleCount
    switch dimensionCount
    case 1
      samples(i, 1) = transformation.evaluateUniform( ...
        (i - 1) / (sampleCount - 1));
    otherwise
      samples(i, :) = transformation.sample(1);
    end

    addition(taskIndex) = samples(i, :);
    schedule.adjustExecutionTime(executionTime + addition);

    powerProfile = power.compute(schedule);
    temperatureProfile = hotspot.compute(powerProfile);

    data(i, :, 1:size(temperatureProfile, 2)) = temperatureProfile;

    progress.increase();
  end
  time = toc;

  save(filename, 'samples', 'data', 'time', '-v7.3');
end

minStepCount = find(all(squeeze(all(data, 1)), 1), 1, 'last');
data = convertKelvinToCelsius(data(:, :, 1:minStepCount));

size(data)

if dimensionCount == 1
  timeSpan = (1:minStepCount) * samplingInterval;
  [ X, Y ] = meshgrid(timeSpan, samples);
end

fprintf('Monte Carlo:\n');
fprintf('  Number of samples:  %d\n', sampleCount);
fprintf('  Simulation time:    %.2f s\n', time);
fprintf('  Minimal time steps: %d\n', minStepCount);
fprintf('  Minimal schedule:   %.2f s\n', minStepCount * samplingInterval);

for i = 1:processorCount
  switch dimensionCount
  case 1
    figure;
    mesh(X, Y, squeeze(data(:, i, :)));
    title(sprintf('Temperature of Core %d', i));
    xlabel('Time, s');
    ylabel('Uncertain parameter');
    zlabel('Temperature, C');
  otherwise
    observeData(data(:, i, timeStep), ...
      'draw', 'true', 'method', 'histogram', 'range', 'unbounded');
    title(sprintf('Temperature of Core %d at time %.2f s', i, timeMoment));
    xlabel('Temperature, C');
    ylabel('Empirical PDF');
  end
end
