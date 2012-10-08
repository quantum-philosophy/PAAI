classdef Constants < handle
  properties (Constant)
    %
    % Directories.
    %
    buildDirectory  = File.join(Constants.root, '..', 'build');
    cacheDirectory  = File.join(Constants.root, '..', 'build', 'cache');
    vendorDirectory = File.join(Constants.root, '..', 'vendor');
    testDirectory   = File.join(Constants.root, '..', 'test');
  end

  methods (Static)
    function path = root
      path = File.trace;
    end
  end
end
