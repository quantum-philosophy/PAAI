classdef Spearman < Correlation.Base
  methods
    function cr = Spearman(varargin)
      cr = cr@Correlation.Base(varargin{:});
    end

    function display(cr)
      fprintf('Spearman''s rho:\n');
      display@Correlation.Base(cr);
    end
  end

  methods (Static)
    function matrix = generate(dimension)
      matrix = Correlation.Pearson.generate(dimension);
      matrix = Correlation.convertPearsonToSpearman(matrix);
    end

    function matrix = compute(rvs)
      matrix = corr(rvs, 'type', 'Spearman');
    end
  end
end
