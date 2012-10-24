function performApproximation(this)
  Terminal.printHeader('Approximation');

  methodParameters = {};

  switch this.method
  case 'PC'
    methodParameters{end + 1} = ...
      this.methodOptions.order;
    methodParameters{end + 1} = ...
      this.methodOptions.quadratureOptions.order;
  end

  filename = sprintf('%s_%s_%s.mat', this.name, this.method, ...
    DataHash({ this.serialize(), methodParameters }));

  if File.exist(filename)
    warning('Loading cached data "%s".', filename);
    load(filename);
  else
    tic;
    switch this.method
    case 'PC'
      approximation = PolynomialChaos.ProbabilistHermite( ...
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
  display(approximation);

  this.approximation = approximation;
end
