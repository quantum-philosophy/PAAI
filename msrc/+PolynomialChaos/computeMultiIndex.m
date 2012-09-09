function multi_index = computeMultiIndex(bounds)
  dim = length(bounds);

  assert(dim > 0, 'The number of dimensions is zero.');
  assert(all(bounds >= 0), 'Negative maximal orders are not valid.');

  %
  % Initialize the multi-index vector.
  %
  multi_index = zeros(0, dim);

  isotropic = all(bounds == bounds(1));
  max_order = max(bounds);

  mi = zeros(1, dim);

  %
  % Add the zeroth chaos.
  %
  multi_index(end + 1, :) = mi;

  %
  % Add the first chaos.
  %
  for i = 1:dim
    if bounds(i) == 0, continue; end
    mi(i) = 1; multi_index(end + 1, :) = mi; mi(i) = 0;
  end

  %
  % Add the other chaoses.
  %
  for order = 2:max_order
    terms = ones(1, order);
    order_complete = false;

    before_count = size(multi_index, 1);

    while ~order_complete
      last_index = order;
      prev_index = order - 1;
      terms(last_index) = 1;

      while terms(last_index) <= terms(prev_index)
        include = true;

        for i = 1:dim
          mi(i) = nnz(terms == i);
          if mi(i) > bounds(i)
            include = false;
            break;
          end
        end

        if include
          multi_index(end + 1, :) = mi;
        end
        terms(last_index) = terms(last_index) + 1;
      end
      [ terms, order_complete ] = increment_terms(...
        terms, last_index, prev_index, dim, order_complete);
    end

    after_count = size(multi_index, 1);

    sort_complete = false;
    while ~sort_complete
      sort_complete = true;

      for i = (before_count + 1):(after_count - 1)
        for j = 1:dim
          if multi_index(i, j) > multi_index(i + 1, j)
            break;
          elseif multi_index(i, j) < multi_index(i + 1, j)
            sort_complete = false;
            temp = multi_index(i, :);
            multi_index(i, :) = multi_index(i + 1, :);
            multi_index(i + 1, :) = temp;
            break;
          end
        end
      end
    end
  end
end

function [ terms, order_complete ] = increment_terms(...
  terms, last_index, prev_index, dim, order_complete)

  increment_complete = false;

  while ~increment_complete
    terms(last_index) = 1;
    terms(prev_index) = terms(prev_index) + 1;

    if prev_index == 1
      increment_complete = true;

      if terms(prev_index) > dim
        order_complete = true;
      end
    else
      last_index = prev_index;
      prev_index = prev_index - 1;

      if terms(last_index) <= terms(prev_index)
        increment_complete = true;
      end
    end
  end
end
