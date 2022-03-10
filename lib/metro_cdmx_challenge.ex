defmodule MetroCdmxChallenge do
  import SweetXml
  @doc """
  Obtains ....

  ## Examples
    iex> MetroCdmxChallenge.metro_lines("./data/tiny_metro.kml")
    [
      %{name: "Línea 5", stations:
        [
          %{name: "Pantitlan", coords: "90.0123113 30.012121"},
          %{name: "Hangares", coords: "90.0123463 30.012158"},
        ]
      },
      %{name: "Línea 3", stations:
        [
          %{name: "Universidad", coords: "90.0123113 30.012121"},
          %{name: "Copilco", coords: "90.0123463 30.012158"},
        ]
      }
    ]
  """
  defmodule Line do
    defstruct [:name, :stations]
  end

  defmodule Station do
    defstruct [:name, :coordinates]
  end
  def metro_lines(xml_path) do
    {:ok, xml_inf} = File.read(xml_path)
    m = xml_inf |> xmap(
      lines: [~x"//Document/Folder[1]/Placemark"l, name: ~x"./name/text()"s, stations: [~x"./LineString/coordinates", coordinates: ~x"./text()"s]], 
    stations: [~x"//Document/Folder[2]/Placemark"l, name: ~x"./name/text()"s, coordinates: ~x"./Point/coordinates/text()"s] )
    stations = Enum.map(m[:stations], fn x-> 
      %{name: x[:name], coordinates: x[:coordinates] 
      |> String.trim} end)
    lines = Enum.map(m[:lines], fn x-> 
      %{name: x[:name], coordinates: x[:stations][:coordinates] 
      |> String.split(~r/\s+/, trim: true)} 
    end)    
    Enum.reduce(lines, [], fn x, acc -> 
      [%Line{name: x[:name], stations: Enum.reduce(x[:coordinates], [], fn x1, acc1 ->
        nm = Enum.filter(stations, fn st -> st[:coordinates] == x1 end)
        cond do       
          nm != nil ->
            nm = List.first(nm)
            nm = nm[:name]
            [%Station{name: nm, coordinates: x1} | acc1]
          true ->
            acc1
        end
      end) }| acc]
    end)
  end
  def metro_graph(xml_path) do
    m_lines = metro_lines(xml_path)
    graph = Graph.new(type: :undirected)
    Enum.reduce(m_lines, graph, fn line, graph ->
      st = Enum.chunk_every(line.stations, 2, 1, :discard) 
      Enum.reduce(st, graph, fn stations, graph -> 
        Graph.add_edge(graph, List.first(stations).name, List.last(stations).name)
      end)
    end)
  end
end 
