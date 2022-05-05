defmodule WordCount do

  def frequencies_tasks(path) do
    path
    |> File.stream!()
    |> Enum.chunk_every(1_000)
    |> Enum.map(fn lines -> Task.async(fn -> count(Enum.join(lines)) end) end)
    |> Enum.map(fn task -> Task.await(task) end)
    |> Enum.reduce(%{}, 
      fn map, acc ->  
        Enum.reduce(map, acc, 
          fn {k, v}, acc ->  
            Map.update(acc, k, v, fn existing_value -> existing_value + v end)
          end) 
      end)
  end
  
  def frequencies(path) do
    path |> File.read! |> count()
  end

  def count(text) do
    text = String.downcase(text)
    text = text |> String.normalize(:nfd) |> String.replace(~r/[^A-z\s]/u,"") |> String.replace(~r/\s\s+/u, " ")
    text = String.split(text, " ", trim: true)
    count(text, %{})
  end

  defp count([], m), do: m 
  defp count([h|t], m) do
    m = Map.put(m, h, Map.get(m, h, 0) + 1)
    count(t, m)
  end
end 
