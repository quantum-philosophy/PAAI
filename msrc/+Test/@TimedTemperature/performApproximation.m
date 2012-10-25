function performApproximation(this)
  performApproximation@Test.Temperature(this);

  this.apExpectation = this.apExpectation(:, this.tempRange);
  this.apVariance = this.apVariance(:, this.tempRange);
end
