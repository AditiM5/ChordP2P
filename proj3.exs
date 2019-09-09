# :observer.start()
[numNodes, numReq] = System.argv

{numNodes, _} = Integer.parse(numNodes)
{numReq, _} = Integer.parse(numReq)

# ets table
data = :ets.new(:data, [:set, :named_table, :public])

# starting the chief GenServer
{:ok, chief_pid} = Chief.start_link([])
Process.register chief_pid, MyChief

Enum.each(0..numNodes-1, fn(i)->
  node_name = ("Node" <> Integer.to_string(i)) |> String.to_atom()
  {:ok, node_pid} = Peer.start_link(20, data, node_name,[])
end)
node_list = Chief.get(MyChief)

IO.puts "Setting up network..."
# creating the first new node - which would create a new chord network
first_node = Enum.fetch!(node_list, 0)
first_node_pid = Chief.lookup(MyChief, first_node)
Peer.create(first_node_pid)

# attaching the rest of the nodes to the same n/w as created above
head = Enum.fetch!(node_list, 0)
tail = Enum.fetch!(node_list, length(node_list)-1)
Peer.set_successor(Chief.lookup(MyChief, tail), head)
Peer.set_predecessor(Chief.lookup(MyChief, head), tail)
Enum.each(1..length(node_list)-1, fn(i)->
  node_pid = Chief.lookup(MyChief, Enum.fetch!(node_list, i))
  Peer.join(node_pid, Enum.fetch!(node_list, i-1))
end)

:timer.sleep(1000)

IO.puts "Sending requests to calculate hop average..."
# Calculating the average number of hops
:ets.insert(data, {:count, 0})
Enum.each(0..numNodes-1, fn(i)->
  current_node = Enum.fetch!(node_list, i)
  node_excl_self = node_list -- [current_node]
  count = 0
  Enum.map(0..numReq-1, fn(j)->
    rand_node = Enum.random(node_excl_self)
    [{_, count}] = :ets.lookup(data, :count)
    res = Utils.find_succ_acc(current_node, rand_node, data, 0)
    :ets.insert(data, {:count, count+res})
  end)
end)
[{_, count}] = :ets.lookup(data, :count)
IO.puts "Average hops: #{(count/(numNodes*numReq))}"