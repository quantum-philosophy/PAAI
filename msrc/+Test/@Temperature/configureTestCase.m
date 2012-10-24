function configureTestCase(this)
  configureTestCase@Test.Approximation(this);

  questions = this.questions;

  questions.append('timeSpan', ...
    'description', 'a time span', ...
    'default', [ 0, 0 ], ...
    'format', '%.3f');

  questions.append('timeSlice', ...
    'description', 'a moment of time to visualize', ...
    'format', '%.3f');

  this.timeSpan = questions.request('timeSpan');

  questions.save();
end
