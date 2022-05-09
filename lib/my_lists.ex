defmodule MyList do
  @moduledoc """
  Documentation for `MyList`.
  """
  @doc """
  Each.

  ## Examples
    iex> MyList.each(["some", "example"], fn x -> IO.puts(x) end)
    "some"
    "example"
    :ok
  """
  def each([], _) do
    :ok
  end
  def each([h|t], f) do
    f.(h)
    each(t, f)
  end

  @doc """
  Map.

  ## Examples
    iex> Enum.map([1, 2, 3], fn x -> x * 2 end)
    [2, 4, 6]
  """
  def map([], _) do
    []
  end
  def map([h|t], f) do
    [f.(h)] ++ map(t, f)
  end

  @doc """
  Reduce.

  ## Examples
    iex> Enum.reduce([1, 2, 3], 0, fn x, acc -> x + acc end)
    6
  """
  def reduce([], ac, _) do
    ac
  end
  def reduce([h|t], ac, f) do
    reduce(t, f.(h, ac), f)
  end 

  @doc """
  Zip.
 
   ## Examples
    iex> Enum.zip([1, 2, 3], [:a, :b, :c])
    [{1, :a}, {2, :b}, {3, :c}]
  """
  def zip([], _) do
    []
  end
  def zip(_, []) do
    []
  end
  def zip([h1|t1], [h2|t2]) do
    [{h1, h2}] ++ zip(t1, t2)
  end

  @doc """
  Zip With.

  ## Examples
    iex> Enum.zip_with([1, 2, 5, 6], [3, 4], fn x, y -> x + y end)
    [4, 6]
  """
  def zip_with([], _, _) do
    []
  end
  
  def zip_with(_, [], _) do
    []
  end
  
  def zip_with([h1|t1], [h2|t2], f) do
    [f.(h1, h2)] ++ zip_with(t1, t2, f)
  end
  
end
