function [ x, data ] = process(x, raw, options)
  method = options.get('method', 'smooth');

  switch method
  case 'smooth'
    [ x, data ] = processKernelDensity(x, raw, options);
  case 'histogram'
    [ x, data ] = processHistogram(x, raw, options);
  case 'piecewise'
    [ x, data ] = processHistogram(x, raw, options);
  otherwise
    error('The method is unknown.');
  end
end

function [ x, data ] = processHistogram(x, raw, options)
  x = x(:);
  raw = raw(:);

  dx = x(2:end) - x(1:end - 1);
  dx = [ dx(1); dx; dx(end) ];

  data = histc(raw, [ -Inf; x; Inf ]);
  data = data(1:end - 1);

  data = data ./ dx / sum(data);
  x = [ x(1) - dx(1); x ];

  switch options.get('function', 'pdf')
  case 'pdf'
  case 'cdf'
    data = cumsum(data);
    data = data / data(end);
  otherwise
    error('The function is unknown.');
  end
end

function [ x, data ] = processKernelDensity(x, raw, options)
  data = ksdensity(raw, x, ...
    'function', options.get('function', 'pdf'));
end
