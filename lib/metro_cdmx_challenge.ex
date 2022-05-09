defmodule MetroCdmxChallenge do
  @moduledoc """
   This module helps to find paths from a station to another from Metro CDMX lines 
  """
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
    @moduledoc """
      This module provides a Struct that contains a Line and its Stations
    """
    defstruct [:name, :stations]
  end

  defmodule Station do
    @moduledoc """
      This module provides a Struct that contains a Station and its coordinates
    """
    defstruct [:name, :coordinates, :line]
  end

  def metro_lines(xml_path) do
    {:ok, xml_inf} = File.read(xml_path)

    map_lines =
      xml_inf
      |> xmap(
        lines: [
          ~x"//Document/Folder[1]/Placemark"l,
          name: ~x"./name/text()"s,
          stations: [~x"./LineString/coordinates", coordinates: ~x"./text()"s]
        ],
        stations: [
          ~x"//Document/Folder[2]/Placemark"l,
          name: ~x"./name/text()"s,
          coordinates: ~x"./Point/coordinates/text()"s
        ]
      )

    stations_raw =
      Enum.map(
        map_lines[:stations],
        fn station ->
          %{
            name: station[:name],
            coordinates:
              station[:coordinates]
              |> String.trim()
          }
        end
      )

    lines_raw =
      Enum.map(
        map_lines[:lines],
        fn line ->
          %{
            name: line[:name],
            coordinates:
              line[:stations][:coordinates]
              |> String.split(~r/\s+/, trim: true)
          }
        end
      )

    Enum.reduce(lines_raw, [], fn line, lines_list ->
      [
        %Line{
          name: line[:name],
          stations:
            Enum.reduce(line[:coordinates], [], fn station_coordinates, stations_list ->
              station = Enum.find(stations_raw, &(&1[:coordinates] == station_coordinates))

              if station != nil do
                [
                  %Station{
                    name: station[:name],
                    coordinates: station_coordinates,
                    line: line.name
                  }
                  | stations_list
                ]
              else
                stations_list
              end
            end)
        }
        | lines_list
      ]
    end)
  end

  def metro_graph(xml_path) do
    graph = Graph.new(type: :directed)

    metro_lines(xml_path)
    |> Enum.reduce(graph, fn line, graph ->
      Enum.chunk_every(line.stations, 2, 1, :discard)
      |> Enum.reduce(
        graph,
        fn stations, graph ->
          Graph.add_edge(graph, List.first(stations).name, List.last(stations).name, label: :lb)
          |> Graph.add_edge(List.last(stations).name, List.first(stations).name, label: :la)
        end
      )
    end)
  end

  def find_line() do
    # TODO
    :line
  end

  def find_station(requested_station) do
    metro_lines("./data/Metro_CDMX.kml")
    |> Enum.map(fn line ->
      Enum.find(line.stations, &(&1.name == requested_station))
    end)
    |> Enum.filter(&(&1 != nil))
  end

  def get_path(source, destiny) do
    path_list =
      metro_graph("./data/Metro_CDMX.kml")
      |> Graph.dijkstra(source, destiny)
      |> trace_route()

    path_index = calculate_line_frecunecies(path_list) |> get_lowest_segments_route

    Enum.at(path_list, path_index)
    |> Enum.map(&Map.from_struct/1)
    |> Enum.chunk_by(& &1.line)
  end

  def trace_route([h | t]) do
    find_station(h)
    |> Enum.map(&[&1])
    |> trace_route(t)
  end

  def trace_route(acc, []) do
    acc
  end

  def trace_route(acc, [h | t]) do
    a = for i <- acc, j <- find_station(h), do: i ++ [j]
    trace_route(a, t)
  end

  def calculate_line_frecunecies(routes) do
    Enum.map(
      routes,
      fn x ->
        Enum.reduce(x, %{}, fn station, acc_map ->
          Map.put(acc_map, station.line, Map.get(acc_map, station.line, 0) + 1)
        end)
      end
    )
  end

  def get_lowest_segments_route(line_frecuencies) do
    segments_count = Enum.map(line_frecuencies, &length(Map.keys(&1)))

    lowest_segments =
      segments_count
      |> Enum.sort()
      |> hd

    segments_count
    |> Enum.find_index(&(&1 == lowest_segments))
  end
end
