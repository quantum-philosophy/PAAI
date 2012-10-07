function setup
  clear all;

  includeLibrary('Interpolation');

  addpath([ root, '/', 'vendor', '/', 'sympoly' ]);
  addpath([ root, '/', 'vendor', '/', 'SPARSE_GRID_HW' ]);
end

function path = root
  chunks = regexp(mfilename('fullpath'), '^(.*)/[^/]+/[^/]+$', 'tokens');
  path = chunks{1}{1};
end
