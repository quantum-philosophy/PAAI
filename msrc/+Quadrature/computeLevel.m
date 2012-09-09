function level = computeLevel(order)
  %
  % Description:
  %
  %   An n-point Gaussian quadrature rule is exact for
  %   polynomials of order (2 * n - 1) or less.
  %
  % Inputs:
  %
  %   * order - the order of the polynomial.
  %

  level = ceil((order + 1) / 2);
end
