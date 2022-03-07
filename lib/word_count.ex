defmodule WordCount do
  def count(text_file) do
    {:ok, text} = File.read(text_file)
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
