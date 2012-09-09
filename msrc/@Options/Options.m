classdef Options < dynamicprops
  methods
    function o = Options(varargin)
      o.update(varargin{:});
    end

    function value = get(o, name, default)
      if isprop(o, name)
        value = o.(name);
      else
        value = default;
      end
    end

    function update(o, varargin)
      count = length(varargin);

      switch count
      case 0
        return;
      case 1
        options = varargin{1};
        assert(isa(options, 'Options'), 'The option format is invalid.');

        names = properties(options);
        for i = 1:length(names)
          if ~isprop(o, names{i}) o.addprop(names{i}); end
          o.(names{i}) = options.(names{i});
        end
      otherwise
        options = struct(varargin{1:end});

        names = fieldnames(options);
        for i = 1:length(names)
          if ~isprop(o, names{i}) o.addprop(names{i}); end
          o.(names{i}) = options.(names{i});
        end
      end
    end

    function display(o)
      fprintf('Options:\n');
      names = properties(o);
      for i = 1:length(names)
        name = names{i};
        value = o.(name);
        if isa(value, 'char')
          fprintf('%10s: %s\n', name, value);
        elseif isa(value, 'double')
          fprintf('%10s: %f\n', name, value);
        else
          fprintf('%10s: <...>\n', name);
        end
      end
    end
  end

  methods (Static = true)
    [ data, options ] = extract(varargin)
  end
end
