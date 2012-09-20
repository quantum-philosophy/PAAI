function draw(this)
  figure;

  processorCount = length(this.platform);
  taskCount = length(this.application);

  colors = Constants.roundRobinColors;

  title('Schedule', 'FontSize', 16);
  xlabel('Time, s', 'FontSize', 14);
  set(gca,'YTick', [], 'YTickLabel', []);

  last = max(this.startTime + this.executionTime);

  taskPower = zeros(taskCount, 1);
  for i = 1:taskCount
    taskPower(i) = this.platform{this.mapping(i)}.dynamicPower(this.application{i}.type);
  end
  taskPower = taskPower ./ max(taskPower);

  processorNames = {};

  maxHeight = 0.8;
  for i = 1:processorCount
    y0 = i;

    ids = find(this.mapping == i);
    [ ~, I ] = sort(this.order(ids));
    ids = ids(I);

    x = [ 0 ];
    y = [ y0 ];
    for j = ids
      startTime = this.startTime(j);
      executionTime = this.executionTime(j);

      height = maxHeight;
      height = height * taskPower(j);

      x(end + 1) = startTime;
      y(end + 1) = y0;

      x(end + 1) = startTime;
      y(end + 1) = y0 + height;

      x(end + 1) = startTime + executionTime;
      y(end + 1) = y0 + height;

      x(end + 1) = startTime + executionTime;
      y(end + 1) = y0;

      text(startTime + 0.2 * executionTime, y0 + 0.3 * maxHeight, ...
        [ 'T', num2str(j) ]);
    end

    x(end + 1) = last;
    y(end + 1) = y0;

    x(end + 1) = 0;
    y(end + 1) = y0;

    color = colors{mod(i - 1, length(colors)) + 1};
    line(x, y, 'Color', color);

    processorNames{end + 1} = [ 'PE', num2str(i) ];
  end

  set(gca, 'YTickLabel', processorNames);
  set(gca, 'YTick', (1:processorCount) + maxHeight / 2);
  set(gca, 'XLim', [ 0 last ]);
end
