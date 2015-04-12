function motivation
  use('Approximation');
  use('Interaction');
  use('UncertaintyQuantification');

  a = 0;
  b = 1;

  x = linspace(a, b, 200).';

  y0 = target(x);

  distribution = ProbabilityDistribution.Beta( ...
    'alpha', 2, 'beta', 2, 'a', a, 'b', b);

  options = Options( ...
    'basis', 'Jacobi', ...
    'inputCount', 1, ...
    'outputCount', 1, ...
    'order', 10, ...
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

  setappdata(0, 'DefaultAxesFontSize', fontSize);
  setappdata(0, 'DefaultAxesXLabelFontSize', fontSize);
  setappdata(0, 'DefaultAxesYLabelFontSize', fontSize);
  setappdata(0, 'DefaultLegendFontSize', fontSize);

  c1 = [237, 177, 32] / 255;
  c2 = [217, 83, 25] / 255;
  c3 = [0, 114, 189] / 255;

  h = Plot.figure(800, 400);
  set(gca(h), 'FontName', fontFamily);

  line(x, y0, 'LineWidth', 3, 'Color', c1);
  line(x, y1, 'LineWidth', 3, 'Color', c2);
  line(x, y2, 'LineWidth', 3, 'Color', c3);

  basis = Basis.Hierarchical.Local.('NewtonCotesHat')(options);
  nodes = basis.computeNodes(output.levels, output.orders);

  line(nodes, 0 * ones(size(nodes)), 'LineStyle', 'None', ...
    'Marker', 'o', 'MarkerSize', 10, 'Color', c3, 'MarkerFaceColor', c3);

  legend('True response', 'Polynomial chaos', ...
    'Adaptive interpolation', 'Adaptive nodes');

  xlabel('Uncertain parameter');
  ylabel('End-to-end delay');

  ylim([-0.1, 1.2]);
end

function y = target(x)
  y = 0.9./(1+exp(-1e10*(x-0.6)))+0.1;
end
