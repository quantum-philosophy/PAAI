function distribution
  use('Interaction');

  alpha = [2, 1, 8, 1];
  beta = [5, 1, 8, 4];

  x = linspace(0, 1, 100).';

  fontFamily = 'Times';
  fontSize = 30;

  set(0,'DefaultAxesFontSize', fontSize);

  h = Plot.figure(800, 400);
  set(gca(h), 'FontName', fontFamily);

  names = {};
  for i = 1:length(alpha)
    line(x, betapdf(x, alpha(i), beta(i)), 'LineWidth', 3, 'Color', Color.pick(i));
    names{end+1} = sprintf('Beta(%.2f, %.2f, a_i, b_i)', alpha(i), beta(i));
  end

  legend(names{:});

  xlabel('Uncertain parameter');
  ylabel('Probability density');

  % ylim([0, 1.1]);
end
