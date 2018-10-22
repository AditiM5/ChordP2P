# :observer.start()
[numNodes, numReq] = System.argv

{numNodes, _} = Integer.parse(numNodes)
{numReq, _} = Integer.parse(numReq)

# ets table
IO.inspect data = :ets.new(:data, [:set, :named_table, :public])


{:ok, chief_pid} = Chief.start_link([])
Process.register chief_pid, MyChief

Enum.each(0..numNodes-1, fn(i)->
  node_name = ("Node" <> Integer.to_string(i)) |> String.to_atom()
  {:ok, node_pid} = Peer.start_link(20, data, node_name,[])
end)

node_list = Chief.get(MyChief)
first_node = Enum.fetch!(node_list, 0)
IO.puts "First node is #{first_node}"
# node_list = node_list -- [first_node]
first_node_pid = Chief.lookup(MyChief, first_node)

Peer.create(first_node_pid)

head = Enum.fetch!(node_list, 0)
tail = Enum.fetch!(node_list, length(node_list)-1)
Peer.set_successor(Chief.lookup(MyChief, tail), head)
Peer.set_predecessor(Chief.lookup(MyChief, head), tail)

Enum.each(1..length(node_list)-1, fn(i)->
  node_pid = Chief.lookup(MyChief, Enum.fetch!(node_list, i))
  Peer.join(node_pid, Enum.fetch!(node_list, i-1))
end)

IO.puts "Last node"
IO.inspect Enum.fetch!(node_list, length(node_list) - 1)

k = :sys.get_state(chief_pid)
IO.puts "This is the chief state"
IO.inspect k

:timer.sleep(5000)
# Enum.each(0..numNodes-1, fn(i)->
#   current_node = Enum.fetch!(node_list, i)
#   [{_, state}] = :ets.lookup(data, current_node)
#   if(state[:id] == state[:succ] || state[:id] == state[:pred]) do
#     # IO.inspect state
#     # IO.puts "State"
#     IO.inspect Peer.get_state(Chief.lookup(MyChief, state[:id]))
#   end
# end
# :ets.insert(data, {:count, 0})
# Enum.each(0..numNodes-1, fn(i)->
#   current_node = Enum.fetch!(node_list, i)
#   node_excl_self = node_list -- [current_node]
#   count = 0
#   Enum.map(0..numReq-1, fn(j)->
#     rand_node = Enum.random(node_excl_self)
#     [{_, count}] = :ets.lookup(data, :count)
#     res = Utils.find_succ_acc(current_node, rand_node, data, 0)
#     :ets.insert(data, {:count, count+res})
#   end)
# end)

# [{_, count}] = :ets.lookup(data, :count)
# IO.puts "Average hops: #{(count/(numNodes*numReq))}"

# k = Enum.random(node_list)
i = 5
k = Enum.fetch!(node_list, i)
k_index = Enum.find_index(node_list, fn i -> i==k end)

IO.puts "Pred"
[{_, state_1}] = :ets.lookup(data, Enum.fetch!(node_list, k_index - 1))
IO.inspect state_1
IO.puts "Succ"
[{_, state_2}] = :ets.lookup(data, Enum.fetch!(node_list, k_index + 1))
IO.inspect state_2


# IO.inspect Peer.get_state(Chief.lookup(MyChief, Enum.fetch!(node_list, k_index - 3)))
# IO.inspect Peer.get_state(Chief.lookup(MyChief, Enum.fetch!(node_list, k_index - 2)))
# IO.inspect Peer.get_state(Chief.lookup(MyChief, Enum.fetch!(node_list, k_index - 1)))

# IO.inspect Peer.get_state(Chief.lookup(MyChief, Enum.fetch!(node_list, k_index + 1)))
# IO.inspect Peer.get_state(Chief.lookup(MyChief, Enum.fetch!(node_list, k_index + 2)))
# IO.inspect Peer.get_state(Chief.lookup(MyChief, Enum.fetch!(node_list, k_index + 3)))

IO.puts "Killing #{k}"
Chief.delete(MyChief, k)

:timer.sleep(20000)
IO.puts "after killing..."

IO.puts "Pred"
[{_, state_1}] = :ets.lookup(data, Enum.fetch!(node_list, k_index - 1))
IO.inspect state_1
IO.puts "Succ"
[{_, state_2}] = :ets.lookup(data, Enum.fetch!(node_list, k_index + 1))
IO.inspect state_2

# IO.inspect Peer.get_state(Chief.lookup(MyChief, Enum.fetch!(node_list, k_index - 3)))
# IO.inspect Peer.get_state(Chief.lookup(MyChief, Enum.fetch!(node_list, k_index - 2)))
# IO.inspect Peer.get_state(Chief.lookup(MyChief, Enum.fetch!(node_list, k_index - 1)))

# IO.inspect Peer.get_state(Chief.lookup(MyChief, Enum.fetch!(node_list, k_index + 1)))
# IO.inspect Peer.get_state(Chief.lookup(MyChief, Enum.fetch!(node_list, k_index + 2)))
# IO.inspect Peer.get_state(Chief.lookup(MyChief, Enum.fetch!(node_list, k_index + 3)))

#Process.exit(k_pid, :kill)

:timer.sleep(10000000)
# IO.inspect count = Utils.find_succ_acc(head, tail, data, 0)