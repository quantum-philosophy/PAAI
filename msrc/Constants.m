classdef Constants < handle
  properties (Constant)
    buildDirectory = [ Constants.thisDirectory, '/../build' ];
  end

  methods (Static)
    function result = thisDirectory
      filename = mfilename('fullpath');
      attrs = regexp(filename, '^(.*)/[^/]+$', 'tokens');
      result = attrs{1}{1};
    end
  end
end
