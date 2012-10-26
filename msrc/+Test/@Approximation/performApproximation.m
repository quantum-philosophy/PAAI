function performApproximation(this)
  filename = sprintf('%s_%s_%s.mat', this.name, this.method, ...
    DataHash({ this.serialize(), this.methodSerialization }));

  if File.exist(filename)
    warning('Loading cached data "%s".', filename);
    load(filename);
  else
    tic;
    switch this.method
    case 'PC'
      approximation = PolynomialChaos.Hermite( ...
        @this.evaluate, this.methodOptions);
    case 'ASGC'
      approximation = ASGC( ...
        @this.evaluate, this.methodOptions);
    case 'HDMR'
      approximation = HDMR( ...
        @this.evaluate, this.methodOptions);
    otherwise
      assert(false);
    end
    time = toc;
    save(filename, 'approximation', 'time', '-v7.3');
  end

  fprintf('Approximation: %.2f s\n', time);

  this.approximation = approximation;
  this.apExpectation = approximation.expectation;
  this.apVariance = approximation.variance;
end
