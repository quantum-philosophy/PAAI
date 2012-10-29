function performApproximation(this)
  performApproximation@Test.Temperature(this);

  this.apExpectation = this.apExpectation(:, this.dataRange);
  this.apVariance = this.apVariance(:, this.dataRange);
end
