classdef Platform < handle
  properties (SetAccess = 'private')
    processors
  end

  methods
    function pl = Platform
    end

    function processor = addProcessor(pl)
      id = pl.processorCount + 1;
      processor = System.Processor(id);
      pl.processors{end + 1} = processor;
    end

    function count = processorCount(pl)
      count = length(pl.processors);
    end

    function display(pl)
      fprintf('Platform:\n');
      fprintf('  Number of processors: %d\n', pl.processorCount);

      fprintf('  Processors:\n');
      fprintf('    %4s ( %5s )\n', 'id', 'types');

      for i = 1:pl.processorCount
        processor = pl.processors{i};
        fprintf('    %4d ( %5d )\n', processor.id, processor.typeCount);
      end
    end
  end
end
