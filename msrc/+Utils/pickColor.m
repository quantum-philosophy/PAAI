function color = pickColor(i)
  if nargin == 0, i = randi(10); end
  colors = Constants.roundRobinColors;
  color = colors{mod(i - 1, length(colors)) + 1};
end
