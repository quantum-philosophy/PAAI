function x = constructLinearSpace(varargin)
  [ data, options ] = Options.extract(varargin{:});
  [ left, right ] = Stats.detectBounds(varargin{:});
  points = options.get('points', max((right - left) / 0.1, 100));
  x = linspace(left, right, points);
end
