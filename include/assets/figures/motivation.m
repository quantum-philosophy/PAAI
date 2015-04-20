function motivation
  use('Approximation');
  use('Interaction');
  use('UncertaintyQuantification');

  a = 0;
  b = 1;

  x = linspace(a, b, 200).';

  y0 = target(x);

  distribution = ProbabilityDistribution.Beta( ...
    'alpha', 1, 'beta', 1, 'a', a, 'b', b);

  options = Options( ...
    'basis', 'Jacobi', ...
    'inputCount', 1, ...
    'outputCount', 1, ...
    'order', 9, ...
    'distribution', distribution ...
  );

  surrogate = PolynomialChaos(options);
  output = surrogate.construct(@target);
  y1 = surrogate.evaluate(output, x);

  options = Options( ...
    'inputCount', 1, ...
    'outputCount', 1, ...
    'absoluteTolerance', 1e-4, ...
    'relativeTolerance', Inf, ...
    'maximalLevel', 10, ...
    'maximalNodeCount', 10, ...
    'verbose', false ...
  );

  surrogate = Interpolation(options);
  output = surrogate.construct(@target);
  y2 = surrogate.evaluate(output, x);

  fontFamily = 'Times';
  fontSize = 30;

  set(0,'DefaultAxesFontSize', fontSize);

  h = Plot.figure(800, 400);
  set(gca(h), 'FontName', fontFamily);

  line(x, y0, 'LineWidth', 3, 'Color', Color.pick(1));
  line(x, y1, 'LineWidth', 3, 'Color', Color.pick(2));
  line(x, y2, 'LineWidth', 3, 'Color', Color.pick(3));

  basis = Basis.Hierarchical.Local.('NewtonCotesHat')(options);
  nodes = basis.computeNodes(output.levels, output.orders);

  line(nodes, 0 * ones(size(nodes)), 'LineStyle', 'None', ...
    'Marker', 'o', 'MarkerSize', 10, 'Color', Color.pick(3), ...
    'MarkerFaceColor', Color.pick(3));

  legend('True response', 'Polynomial chaos', ...
    'Adaptive interpolation', 'Adaptive nodes');

  xlabel('Uncertain parameter');
  ylabel('End-to-end delay');

  ylim([-0.1, 1.2]);
end

function y = target(x)
  y = 0.9./(1+exp(-1e10*(x-0.6)))+0.1;
end
