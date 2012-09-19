classdef Base < handle
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
