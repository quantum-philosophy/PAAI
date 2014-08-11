function fullpath = resolvePath(file, type)
  if file(1) == '#'
    fullpath = File.join(pwd, file(2:end));
  else
    if nargin < 2, type = 'build'; end
    fullpath = File.join(Constants.([ type, 'Directory' ]), file);
  end
end
