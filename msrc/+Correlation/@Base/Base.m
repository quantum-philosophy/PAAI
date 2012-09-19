classdef Base < handle
  properties (SetAccess = 'protected')
    dimension
    matrix
  end

  methods
    function this = Base(matrix)
      assert(size(matrix, 1) == size(matrix, 2), ...
        'A correlation matrix should be a square matrix.');

      this.matrix = matrix;
      this.dimension = size(matrix, 1);
    end
  end

  methods (Static, Abstract)
    matrix = random(dimension)
    matrix = compute(data)
  end
end
