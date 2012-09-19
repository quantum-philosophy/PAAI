classdef Base < handle
  properties (SetAccess = 'protected')
    mu
    sigma
  end

  methods
    function pd = Base()
    end
  end

  methods (Abstract)
    data = sample(this, samples, dimension)
    data = apply(this, data)
    data = invert(this, data)
  end
end
