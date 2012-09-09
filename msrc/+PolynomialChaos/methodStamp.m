function s = methodStamp(method)
  s = sprintf('PolynomialChaos(%s_%s_co%d)', ...
    method.chaosName, method.chaosType, method.chaosOrder);
end
