defmodule ProcessRingFixed do
  def init(n) do
    pids = Enum.map(1..n, fn _ -> spawn(&wait_for_config/0) end)
    next_pids = Enum.drop(pids, 1) ++ [hd(pids)]
    ring_config = Enum.zip(pids, next_pids)

    ring_config
    |> hd()
    |> then(fn {pid, next} -> send(pid, {:config, next, true}) end)

    ring_config
    |> Enum.drop(1)
    |> Enum.each(fn {pid, next_pid} ->
      send(pid, {:config, next_pid, false})
    end)
    hd(pids)
  end

  def rounds(pid, msg, t) do
    send(pid, {msg, 0, t})
    :ok
  end

  def wait_for_config() do
    receive do
      {:config, next_pid, main} ->
        IO.puts("pid: #{inspect(self())}, next: #{inspect(next_pid)} main: #{main}")
        process_msg(next_pid, main)
      _ -> :ok
    end
  end

  def process_msg(next, main) do
    receive do
      {msg, 0, t} -> send(next, {msg, 1, t})
      {msg, n, t} ->
        IO.puts("Process #{inspect(self())} received message \"#{msg}\", round #{n}")
        cond do
          main and n < t -> send(next, {msg, n + 1 , t})
          main -> :ok
          true -> send(next, {msg, n, t})
        end
      _ -> :ok
    end
    process_msg(next, main)
  end
end
