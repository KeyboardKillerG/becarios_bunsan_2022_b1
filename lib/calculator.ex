defmodule Calculator do
  def init(n) do
   calc(n) 
  end

  def calc(n) do
    n = receive do
      {:sum,  x, pid} -> send(pid, {:state, n + x}); n + x
      {:sub,  x, pid} -> send(pid, {:state, n - x}); n - x
      {:mult, x, pid} -> send(pid, {:state, n * x}); n * x
      {:div,  x, pid} -> send(pid, {:state, n / x}); n / x
      _ -> IO.puts "That seems crazy!"; n
    end
    calc(n)
  end

  def count(n) do
    state = receive do
      {:count, pid} ->
        send(pid, {:state, n + 1})
        n + 1
      _ -> n
    end
    count(state)
  end
end

defmodule CalculatorAgent do
  use Agent

  def init(n) do
    Agent.start(fn -> n end)
  end

  def sum(pid, val), do: Agent.update(pid, &(&1 + val))
  def sub(pid, val), do:  Agent.update(pid, &(&1 - val)) 
  def mult(pid, val), do: Agent.update(pid, &(&1 * val))
  def div(pid, val), do: Agent.update(pid, &(&1 / val))


  def state(pid) do
    Agent.get(pid, & &1)
  end

end
