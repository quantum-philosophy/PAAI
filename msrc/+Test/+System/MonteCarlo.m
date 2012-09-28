init;

samples = 1e2;

[ platform, application, schedule, parameters ] = Test.Case.constructBeta('002_020');

%% Perform the probability transformation.
%
transformation = Transformation.Normal(parameters);

executionTime = schedule.executionTime;
startTime = zeros(samples, length(application));

tic;
for i = 1:samples
  schedule.adjustExecutionTime( ...
    executionTime + transformation.sample(1));

  startTime(i, :) = schedule.startTime;
end
time = toc;

fprintf('Monte Carlo:\n');
fprintf('  Samples: %d\n', samples);
fprintf('  Simulation time: %.2f s\n', time);

for i = 2:10
  Stats.observe(startTime(:, i), ...
    'draw', 'true', 'method', 'histogram', 'range', 'unbounded');
  title([ 'Start time of Task ', num2str(i) ]);
  xlabel('Time, s');
  ylabel('Empirical PDF');
end
