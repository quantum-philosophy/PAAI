classdef Spearman < Correlation.Base
  methods
    function cr = Spearman(varargin)
      cr = cr@Correlation.Base(varargin{:});
      cr.matrix = Correlation.Spearman.generate(cr.dimension);
    end
  end

  methods (Static)
    function Cs = generate(dimension)
      Cp = Correlation.Pearson.generate(dimension);
      Cs = Correlation.convertPearsonToSpearman(Cp);
    end
  end
end
