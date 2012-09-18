classdef Pearson < Correlation.Base
  methods
    function cr = Pearson(varargin)
      cr = cr@Correlation.Base(varargin{:});
      cr.matrix = Correlation.Pearson.generate(cr.dimension);
    end
  end

  methods (Static)
    function Cp = generate(dimension)
      S = randn(dimension);
      S = S' * S;
      Cp = corrcov(S);
    end
  end
end
