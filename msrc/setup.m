function setup
  evalin('base', 'clear all');

  includeLibrary('Interpolation');
  includeLibrary('SystemSimulation');
  includeLibrary('TemperatureAnalysis');
  includeLibrary('ProbabilityTheory');

  path = File.trace();
  addpath(File.join(path, '..', 'vendor', 'sympoly'));
  addpath(File.join(path, '..', 'vendor', 'SPARSE_GRID_HW'));
end
