function index = computeMultiIndex(dim, maxOrder, weights, space)
  if nargin < 3 || isempty(weights), weights = ones(1, dim); end
  if nargin < 4, space = 'TO'; end

  assert(dim > 0, 'The dimension is invalid.');
  assert(maxOrder >= 0, 'The order is invalid.');
  assert(nnz(weights < 0 | weights > 1) == 0, 'The weights are invalid.');

  switch upper(space)
  case 'TP'
    index = constructTensorProduct(dim, maxOrder);
    weights = repmat(weights, size(index, 1), 1);
    I = max(index .* weights, [], 2) <= maxOrder;
  case 'TO'
    valid = @(index) sum(index .* weights) <= maxOrder;
    index = constructTotalOrder(dim, maxOrder);
    weights = repmat(weights, size(index, 1), 1);
    I = sum(index .* weights, 2) <= maxOrder;
  otherwise
    error('The polynomial space is unknown.');
  end

  %
  % (+1) since now everything starts from 0.
  %
  index = index(I, :) + 1;
end

function index = constructTensorProduct(dim, maxOrder)
  vecs = {};

  for i = 1:dim
    vecs{end + 1} = 0:maxOrder;
  end

  [ vecs{:} ] = ndgrid(vecs{:});
  index = reshape(cat(dim + 1, vecs{:}), [], dim);
end

function Index = constructTotalOrder(dim, maxOrder)
  Index = zeros(0, dim);

  index = zeros(1, dim);

  %
  % Add the zeroth chaos.
  %
  Index(end + 1, :) = index;
  done = 1;

  if maxOrder == 0, return; end

  %
  % Add the first chaos.
  %
  for i = 1:dim
    index(i) = 1;
    Index(end + 1, :) = index;
    done = done + 1;
    index(i) = 0;
  end
  if maxOrder == 1, return; end

  p = zeros(maxOrder, dim);
  p(1, :) = 1;

  for order = 2:maxOrder
    fixedDone = done;

    for i = 1:dim
      p(order, i) = sum(p(order - 1, i:dim));
    end

    for i = 1:dim
      for j = (fixedDone - p(order, i)):(fixedDone - 1)
        index = Index(j + 1, :);
        index(i) = index(i) + 1;

        Index(end + 1, :) = index;
        done = done + 1;
      end
    end
  end
end
