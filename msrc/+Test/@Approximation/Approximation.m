classdef Approximation < handle
  properties (Constant)
    independent = true;
    sampleCount = 1e3;
  end

  properties (SetAccess = 'protected')
    name

    questions

    platform
    application

    method
    methodOptions

    processorCount
    taskCount

    processorIndex
    taskIndex

    inputDimension
    outputDimension

    schedule

    parameters
    transformation

    approximation

    apExpectation
    apVariance

    mcSamples
    mcData

    mcExpectation
    mcVariance
  end

  methods
    function this = Approximation(name)
      this.name = name;

      this.questions = Terminal.Questionnaire( ...
        sprintf('Approximation_questions.mat', name));

      this.methodOptions = Options();

      Terminal.printHeader('Configuration of the system');
      this.configureTestCase();

      this.configureSystem();
      this.configureParameters();

      Terminal.printHeader('Configuration of the approximation method');
      this.configureMethod();
      display(this.methodOptions);

      Terminal.printHeader('Construction of the approximation');
      this.performApproximation();
      display(this.approximation);

      Terminal.printHeader('Monte Carlo simulations');
      this.performMonteCarlo();

      Terminal.printHeader('Assessment of the approximation');
      this.assessApproximation();

      this.visualizeApproximation();
    end
  end

  methods (Access = 'protected')
    configureTestCase(this)
    configureSystem(this)
    configureParameters(this)
    configureMethod(this)

    performApproximation(this)
    performMonteCarlo(this)

    assessApproximation(this)

    visualizeApproximation(this)

    data = simulate(this, rvs)
    data = approximate(this, rvs)

    data = serialize(this)
  end

  methods (Abstract, Access = 'protected')
    data = evaluate(this, rvs)
  end
end
