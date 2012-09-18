classdef Pearson < Correlation.Base
  methods
    function cr = Pearson(varargin)
      cr = cr@Correlation.Base(varargin{:});
    end
  end

  methods (Static)
    function matrix = generate(dimension)
      S = randn(dimension);
      S = S' * S;
      matrix = corrcov(S);
    end

    function matrix = compute(rvs)
      matrix = corr(rvs, 'type', 'Pearson');
    end
  end
end
