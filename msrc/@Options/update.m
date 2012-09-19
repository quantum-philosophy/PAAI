function update(this, varargin)
  count = length(varargin);

  switch count
  case 0
    return;
  case 1
    options = varargin{1};
    assert(isa(options, 'Options'), 'The option format is invalid.');

    names = properties(options);
    for i = 1:length(names)
      if ~isprop(this, names{i}) this.addprop(names{i}); end
      this.(names{i}) = options.(names{i});
    end
  otherwise
    options = struct();

    for i = 1:(count / 2)
      options.(varargin{2 * (i - 1) + 1}) = varargin{2 * (i - 1) + 2};
    end

    names = fieldnames(options);
    for i = 1:length(names)
      if ~isprop(this, names{i}) this.addprop(names{i}); end
      this.(names{i}) = options.(names{i});
    end
  end
end
