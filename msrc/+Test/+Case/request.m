function [ platform, application, floorplan, hotspotConfig, hotspotLine ] = ...
  request(varargin)

  options = Options(varargin{:});

  samplingInterval = options.get('samplingInterval', 1e-3);
  processorCount = options.get('processorCount', 2);

  fprintf('Test case:\n');
  fprintf('  Number of processing elements [%d]: ', processorCount);

  out = input('');
  if ~isempty(out), processorCount = out; end

  taskCount = options.get('taskCount', 10 * processorCount);

  fprintf('  Number of tasks [%d]: ', taskCount);

  out = input('');
  if ~isempty(out), taskCount = out; end

  tgffFilename = Utils.resolvePath( ...
    sprintf('%03d_%03d.tgff', processorCount, taskCount));

  [ platform, application ] = parseTGFF(tgffFilename);

  floorplan = Utils.resolvePath( ...
    sprintf('%03d.flp', processorCount), 'test');
  hotspotConfig = Utils.resolvePath( ...
    'hotspot.config', 'test');
  hotspotLine = sprintf('sampling_intvl %e', samplingInterval);
end
