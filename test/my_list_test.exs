defmodule MyListTest do
  use ExUnit.Case
  doctest MyList

  test "MyList Each Test" do
    assert MyList.each([1, 2, 3], fn x -> x + 1 end) == :ok
  end

  test "MyList Map Test" do
    assert MyList.map([1, 2, 3], fn x -> x + 1 end) == [2, 3, 4]
  end

  test "MyList Reduce Test" do
    assert MyList.reduce([1, 2, 3], 0, fn x, acc -> x + acc end) == 6
  end

  test "MyList Zip Test" do
    assert MyList.zip([1, 2, 3, 4, 5], [:a, :b, :c]) == [{1, :a}, {2, :b}, {3, :c}]
  end

  test "MyList Zip_With Test" do
    assert MyList.zip_with([1, 2], [3, 4, 5, 6], fn x, y -> x + y end) == [4, 6]
  end
end
