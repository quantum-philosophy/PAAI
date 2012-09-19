function line = string(this)
  line = '';
  names = properties(this);

  for i = 1:length(names)
    name = names{i};
    value = this.(name);

    if isa(value, 'char')
      chunk = sprintf('%s_%s', name, value);
    elseif isa(value, 'double')
      chunk = sprintf('%s_%d', name, value);
    else
      chunk = name;
    end

    if i == 1
      line = chunk;
    else
      line = [ line, '_', chunk ];
    end
  end
end
