function debug(varargin)
  format = '';
  arguments = {};

  for i = 1:length(varargin)
    current = varargin{i};
    if isa(current, 'cell')
      format = [ format, current{1}, '\n' ];
      arguments = { arguments{:}, current{2:end} };
    else
      if isempty(format)
        format = current;
      else
        arguemnts{end + 1} = current;
      end
    end
  end

  fprintf('------------------------------\n');
  fprintf(format, arguments{:});
  fprintf('------------------------------\n');
end
