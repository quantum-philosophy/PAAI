function data = simulate(this, rvs)
  data = this.evaluate(rvs);
  data = data(:, this.tempRange);
end
