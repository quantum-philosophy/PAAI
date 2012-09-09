function s = methodStamp(method)
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

  s = sprintf('Quadrature(%s_%s_co%d_qo%s_ql%s)', ...
    method.quadratureName, method.quadratureType, ...
    method.chaosOrder, order, level);
end
