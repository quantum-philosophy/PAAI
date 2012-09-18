classdef Base < handle
  properties (SetAccess = 'protected')
    parameters
  end

  methods
    function pt = Base(up)
      pt.parameters = up;
    end

    function rvs = sample(pt, samples)
      rvs = pt.apply(pt.generate(samples));
    end
  end

  methods (Abstract)
    rvs = generate(pt, samples)
    rvs = apply(pt, rvs)
  end
end
