function [ globalError, localError ] = compare(varargin)
  [ raw, options ] = Options.extract(varargin{:});
  assert(length(raw) == 2, 'The comparison is supported only for two sets of data.');

  mcSize = size(raw{1});
  pcSize = size(raw{2});

  dims = length(mcSize);

  assert(dims == length(pcSize), 'The dimensions are invalid.');
  assert(dims == 2 || dims == 3, 'The given number of dimensions is not supported.');

  if dims == 2
    [ globalError, localError ] = compare2D(raw{1}, raw{2}, options);
  else
    [ globalError, localError ] = compare3D(raw{1}, raw{2}, options);
  end
end

function [ globalError, localError ] = compare2D(mcRaw, pcRaw, options)
  [ ~, ddim ] = size(mcRaw);
  assert(ddim == size(pcRaw, 2), 'The dimensions are invalid.');

  draw = options.get('draw', false);

  if draw, figure; end

  localError = zeros(1, ddim);

  for i = 1:ddim
    if draw, p = subplot(1, ddim, i); end

    mcraw = mcRaw(:, i);
    pcraw = pcRaw(:, i);

    x = Stats.constructLinearSpace(mcraw, pcraw, options);

    [ mcx, mcData ] = Stats.process(x, mcraw, options);
    [ pcx, pcData ] = Stats.process(x, pcraw, options);

    assert(nnz(mcx - pcx) == 0, 'The supports are invalid.');

    localError(i) = Stats.NRMSE(mcData, pcData);

    if draw
      Stats.draw(mcx, mcData, pcData, options);
      title(sprintf('NRMSE %.2f %%', localError(i) * 100));
      labels = options.get('labels', { 'MC', 'PC' });
      legend(labels{:});
    end
  end

  globalError = sqrt(sum(localError .^ 2) / ddim);
end

function [ globalError, localError ] = compare3D(mcRaw, pcRaw, options)
  [ ~, ddim, tdim ] = size(mcRaw);
  assert(ddim == size(pcRaw, 2) && tdim == size(pcRaw, 3), ...
    'The dimensions are invalid.');

  draw = options.get('draw', false);
  options.update('draw', false);

  h = ibar('Comparison: step %d out of %d.', tdim);

  localError = zeros(ddim, tdim);

  for i = 1:tdim
    [ ~, localError(:, i) ] = compare2D(mcRaw(:, :, i), pcRaw(:, :, i), options);
    increase(h);
  end

  globalError = sqrt(sum(localError(:) .^ 2) / (ddim * tdim));

  if ~draw, return; end

  figure;

  labels = {};
  time = 0:(tdim - 1);

  for i = 1:ddim
    labels{end + 1} = num2str(i);
    line(time, localError(i, :) * 100, 'Color', Utils.pickColor(i));
  end

  title('Error Evolution');
  ylabel('NRMSE, %');
  legend(labels{:});
end
