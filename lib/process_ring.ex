defmodule ProcessRing do
  def init(n) do
    pids = Enum.map(1..n, fn x -> spawn(ProcessRing, :ring_process, [0, List.to_string([x+64])]) end)
    pids = pids ++ [hd pids]
    pid_pairs = Enum.chunk_every(pids, 2, 1, :discard)
    Enum.each(pid_pairs, fn [pid_a, pid_b] -> send(pid_a, {:point_to, pid_b})  end)
    pids
  end

  def ring_process(point_to, name) do
    #IO.puts(name)
    #IO.puts(inspect(point_to))
    point_to = receive do
      {:loop, data} -> 
        msg = data.msg
        [round, hop, total_rounds, total_hops] = data.control
        if round <= total_rounds do
          if hop < total_hops do
            IO.puts("From process: #{name}, msg: #{msg}, round: #{round}")
            #IO.puts(inspect(point_to))
            send(point_to, {:loop, %{control: [round, hop + 1, total_rounds, total_hops ], msg: msg}})
            point_to
          else
            IO.puts("From process: #{name}, msg: #{msg}, round: #{round}")
            send(point_to, {:loop, %{control: [round + 1, 1, total_rounds, total_hops], msg: msg}})
            point_to
          end
        else
          point_to
        end
      {:point_to, point_to} -> 
        point_to
    end
    ring_process(point_to, name)
  end

  def rounds(ring, msg, rounds) do
    control = [1, 1, rounds, length(ring) - 1]
    data = %{control: control, msg: msg}
    send(hd(ring), {:loop, data})
    :ok
  end
end
