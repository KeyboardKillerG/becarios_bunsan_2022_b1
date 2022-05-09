defmodule FizzBuzzTest do
  use ExUnit.Case
  doctest FizzBuzz

  test "FizzBuzz Test" do
    assert FizzBuzz.fizzbuzz(100) == :ok
  end
end
