function configureTestCase(this)
  skip = Terminal.question('Use the previous settings? ');

  if skip, this.questions.autoreply(); end

  questions = this.questions;

  questions.append('method', ...
    'description', 'the approximation method (MC, PC, ASGC, HDMR)', ...
    'type', 'char', 'default', 'MC');

  questions.append('processorCount', ...
    'description', 'the number of processing elements', ...
    'type', 'uint8', 'default', uint8(2));

  questions.append('taskCount', ...
    'description', 'the number of tasks', ...
    'type', 'uint16');

  questions.append('processorIndex', ...
    'description', 'a processor to inspect', ...
    'type', 'uint8', 'default', uint8(1));

  questions.append('taskIndex', ...
    'description', 'a task set to inspect', ...
    'type', 'uint8', 'default', uint8(1));

  questions.append('rvIndex', ...
    'description', 'an independent RV to visualize', ...
    'type', 'uint8');

  this.processorCount = questions.request('processorCount');

  this.taskCount = questions.request('taskCount', ...
    'default', 10 * this.processorCount);

  this.method = upper(questions.request('method'));

  this.processorIndex = questions.request('processorIndex');

  this.taskIndex = questions.request('taskIndex');

  switch this.method
  case 'MC'
    this.onlyMC = true;
  case 'PC'
    questions.append('polynomialOrder', ...
      'description', 'the polynomial order', ...
      'format', '%d', 'default', 3);

    questions.append('quadratureLevel', ...
      'description', 'the quadrature level', ...
      'format', '%d');

    this.methodOptions.set('order', ...
      questions.request('polynomialOrder'));

    this.methodOptions.set('quadratureOptions', Options( ...
      'level', questions.request('quadratureLevel', ...
        'default', this.methodOptions.order + 1)));
  end

  questions.save();
end
