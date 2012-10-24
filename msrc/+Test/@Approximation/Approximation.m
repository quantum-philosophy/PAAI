classdef Approximation < handle
  properties (Constant)
    independent = true;
    sampleCount = 1e4;
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

    mcSamples
    mcData

    mcExpectation
    mcVariance
  end

  methods
    function this = Approximation(name)
      this.name = name;

      this.questions = Terminal.Questionnaire( ...
        sprintf('%s_questions.mat', name));

      this.methodOptions = Options();

      this.configureTestCase();
      this.configureSystem();
      this.configureParameters();
      this.configureMethod();

      this.performApproximation();
      this.performMonteCarlo();

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

    data = serialize(this)
  end

  methods (Abstract, Access = 'protected')
    data = evaluate(this, rvs)
  end
end
