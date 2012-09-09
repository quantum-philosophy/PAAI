function one = merge(one, two)
  names = fieldnames(two);
  for i = 1:length(names)
    name = names{i};
    one.(name) = two.(name);
  end
end
