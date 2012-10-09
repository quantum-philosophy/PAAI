setup;
includeLibrary('Vendor/DataHash');

samplingInterval = 1e-4;
sampleCount = 1e2;

%% Select what we want to observe.
%
timeMoment = 0.1;
timeStep = floor(timeMoment / samplingInterval);

%% Configuration.
%
[ platform, application, floorplan, hotspotConfig, hotspotLine ] = ...
  Test.Case.request('samplingInterval', samplingInterval);

processorCount = length(platform);
taskCount = length(application);

taskIndex = 1:taskCount;

fprintf('  Task number to inspect (1-%d) [all]: ', taskCount);
out = input('');

if ~isempty(out), taskIndex = out; end

[ schedule, parameters ] = Test.Case.constructBeta(platform, application, ...
  'taskIndex', taskIndex, 'alpha', 1.4, 'beta', 3, 'deviation', 0.7);

executionTime = schedule.executionTime;

%% Perform the probability transformation.
%
transformation = ProbabilityTransformation.Normal(parameters);

dimensionCount = transformation.dimension;

%% Initialize the power computation.
%
power = PowerProfile(samplingInterval);

%% Initialize the temperature simulator.
%
hotspot = HotSpot.Analytic(floorplan, hotspotConfig, hotspotLine);

maxStepCount = floor(1.5 * duration(schedule) / samplingInterval);

filename = sprintf('HotSpot_simulate_%s.mat', ...
  DataHash({ processorCount, taskCount, taskIndex, ...
    samplingInterval, sampleCount }));

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

if dimensionCount == 1
  timeSpan = (1:minStepCount) * samplingInterval;
  [ X, Y ] = meshgrid(timeSpan, samples + executionTime(taskIndex));
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
    ylabel(sprintf('Execution time of Task %d', taskIndex));
    zlabel('Temperature, C');
    xlim([ min(min(X)), max(max(X)) ]);
    ylim([ min(min(Y)), max(max(Y)) ]);
    view([ 0 90 ]);
    colormap('jet');
    colorbar;
  otherwise
    observeData(data(:, i, timeStep), ...
      'draw', 'true', 'method', 'histogram', 'range', 'unbounded');
    title(sprintf('Temperature of Core %d at time %.2f s', i, timeMoment));
    xlabel('Temperature, C');
    ylabel('Empirical PDF');
  end
end
