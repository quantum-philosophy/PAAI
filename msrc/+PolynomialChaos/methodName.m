function s = methodName(method)
  s = sprintf('%s (%s), order %d', ...
    method.chaosName, method.chaosType, method.chaosOrder);
end
