classdef Base < handle
  properties (SetAccess = 'protected')
    dimension
    matrix
  end

  methods
    function cr = Base(dimension, rvs)
      cr.dimension = dimension;

      if nargin > 1
        cr.matrix = cr.compute(rvs);
        assert(all(size(cr.matrix) == dimension), ...
          'The given data are invalid.');
      else
        cr.matrix = cr.generate(dimension);
      end
    end

    function display(cr)
      for i = 1:cr.dimension
        for j = 1:cr.dimension
          fprintf('%5.2f\t', cr.matrix(i, j));
        end
        fprintf('\n');
      end
    end
  end

  methods (Static, Abstract)
    matrix = generate(dimension)
    matrix = compute(rvs)
  end
end
