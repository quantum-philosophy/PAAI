classdef Constants < handle
  properties (Constant)
    %
    % Directories.
    %
    buildDirectory = [ Constants.thisDirectory, '/../build' ];
    cacheDirectory = [ Constants.thisDirectory, '/../build/cache' ];
    vendorDirectory = [ Constants.thisDirectory, '/../vendor' ];

    %
    % Visualization.
    %
    roundRobinColors = { ...
      [ 87, 181, 232] / 255, ...
      [ 230, 158, 0 ] / 255, ...
      [ 129, 197, 122 ] / 255, ...
      [ 20, 43, 140 ] / 255, ...
      [ 195, 0, 191 ] / 255 };
  end

  methods (Static)
    function result = thisDirectory
      filename = mfilename('fullpath');
      attrs = regexp(filename, '^(.*)/[^/]+$', 'tokens');
      result = attrs{1}{1};
    end
  end
end
