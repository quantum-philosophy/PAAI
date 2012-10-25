function data = approximate(this, rvs)
  data = this.approximation.evaluate(rvs);
  data = data(:, this.tempRange);
end
