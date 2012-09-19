function display(this)
  for i = 1:this.dimension
    for j = 1:this.dimension
      fprintf('%5.2f\t', this.matrix(i, j));
    end
    fprintf('\n');
  end
end
