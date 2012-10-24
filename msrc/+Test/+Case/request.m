function [ platform, application, floorplan, hotspotConfig, hotspotLine ] = ...
  request(varargin)

  options = Options(varargin{:});

  silent = options.get('silent', false);

  samplingInterval = options.get('samplingInterval', 1e-4);

  processorCount = uint16(options.get('processorCount', 2));
  taskCount = uint16(options.get('taskCount', 10 * processorCount));

  if ~silent
    questions = Terminal.Questionnaire('TC_questions.mat');

    questions.append('processorCount', ...
      'description', 'the number of processing elements', ...
      'default', processorCount, 'type', 'uint16');

    questions.append('taskCount', ...
      'description', 'the number of tasks', ...
      'type', 'uint16');

    questions.load();

    processorCount = questions.request('processorCount');
    taskCount = questions.request('taskCount', ...
      'default', 10 * processorCount);

    questions.save();
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
