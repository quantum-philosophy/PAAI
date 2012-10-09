function [ platform, application, floorplan, hotspotConfig, hotspotLine ] = ...
  request(varargin)

  options = Options(varargin{:});

  silent = options.get('silent', false);

  samplingInterval = options.get('samplingInterval', 1e-3);

  fprintf('Test case:\n');

  %
  % Pick a number of processing elements.
  %
  processorCount = options.get('processorCount', 2);

  if ~silent
    fprintf('  Number of processing elements [%d]: ', processorCount);
    processorCount = Input.read('default', processorCount);
  end

  %
  % Pick a number of tasks.
  %
  taskCount = options.get('taskCount', 10 * processorCount);

  if ~silent
    fprintf('  Number of tasks [%d]: ', taskCount);
    taskCount = Input.read('default', taskCount);
  end

  tgffFilename = Utils.resolvePath( ...
    sprintf('%03d_%03d.tgff', processorCount, taskCount));

  [ platform, application ] = parseTGFF(tgffFilename);

  floorplan = Utils.resolvePath( ...
    sprintf('%03d.flp', processorCount), 'test');
  hotspotConfig = Utils.resolvePath( ...
    'hotspot.config', 'test');
  hotspotLine = sprintf('sampling_intvl %e', samplingInterval);
end
