setup;

sampleCount = 1e2;

%% Configuration.
%
[ platform, application ] = Test.Case.request();
[ schedule, parameters ] = Test.Case.constructBeta(platform, application);

%% Perform the probability transformation.
%
transformation = ProbabilityTransformation.Normal(parameters);

executionTime = schedule.executionTime;

filename = sprintf('System_simulate_%s.mat', ...
  DataHash({ length(platform), length(application), sampleCount }));

if File.exist(filename)
  load(filename);
else
  data = zeros(sampleCount, length(application));

  tic;
  for i = 1:sampleCount
    schedule.adjustExecutionTime( ...
      executionTime + transformation.sample(1));

    data(i, :) = schedule.startTime;
  end
  time = toc;

  save(filename, 'data', 'time', '-v7.3');
end

fprintf('Monte Carlo:\n');
fprintf('  sampleCount: %d\n', sampleCount);
fprintf('  Simulation time: %.2f s\n', time);

for i = 2:10
  observeData(data(:, i), ...
    'draw', 'true', 'method', 'histogram', 'range', 'unbounded');
  title([ 'Start time of Task ', num2str(i) ]);
  xlabel('Time, s');
  ylabel('Empirical PDF');
end
