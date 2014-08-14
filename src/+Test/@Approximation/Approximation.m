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
    methodSerialization

    onlyMC

    processorCount
    taskCount

    processorIndex
    taskIndex

    inputCount
    outputCount

    scheduler
    schedule

    parameters
    transformation

    mcSamples

    mcExpectation
    mcVariance
    mcData

    approximation

    apExpectation
    apVariance
    apData
  end

  methods
    function this = Approximation(name)
      this.name = name;
      this.onlyMC = false;

      this.questions = Questionnaire( ...
        'Approximation_questions.mat');

      this.methodOptions = Options();

      Print.header('Configuration of the system');
      this.configureTestCase();

      this.configureSystem();
      this.configureParameters();

      Print.header('Monte Carlo simulations');
      this.performMonteCarlo();

      if ~this.onlyMC
        Print.header('Configuration of the approximation method');
        this.configureMethod();
        display(this.methodOptions);

        Print.header('Construction of the approximation');
        this.performApproximation();
        display(this.approximation);

        Print.header('Assessment of the approximation');
        this.assessApproximation();
      end

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
