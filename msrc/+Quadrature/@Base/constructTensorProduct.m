function [ nodes, weights, Nqp ] = constructTensorProduct(qd, Nsd, Nqo)
  [ nodes1D, weights1D ] = qd.construct1D(Nqo);

  nodes = {};
  weights = {};

  for i = 1:Nsd
    nodes{end + 1} = nodes1D;
    weights{end + 1} = weights1D;
  end

  [ nodes, weights ] = tensor_product(nodes, weights);

  nodes = transpose(nodes);
  weights = transpose(weights);

  Nqp = size(weights, 2);
  assert(Nqp == Nqo^Nsd);
end
