function s = methodName(method)
  if isfield(method, 'quadratureOrder') && ~isempty(method.quadratureOrder)
    order = num2str(method.quadratureOrder);
  else
    order = 'X';
  end

  if isfield(method, 'quadratureLevel') && ~isempty(method.quadratureLevel)
    level = num2str(method.quadratureLevel);
  else
    level = 'X';
  end

  s = sprintf('%s (%s), order %s, level %s', ...
    method.quadratureName, method.quadratureType, order, level);
end
