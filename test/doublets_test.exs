defmodule DoubletsTest do
  use ExUnit.Case

  test "Find solution, solution in list" do
    assert Doublets.Solver.find_solution(
             [
               ["head", "heal", "teal", "tell", "tall", "tail"],
               ["head", "heal", "teal", "tell", "tall", "call"]
             ],
             "tail"
           ) ==
             ["head", "heal", "teal", "tell", "tall", "tail"]
  end

  test "Find solution, solution not in list" do
    assert Doublets.Solver.find_solution(
             [
               ["head", "heal", "teal", "tell", "tall", "fall"],
               ["head", "heal", "teal", "tell", "tall", "call"]
             ],
             "tail"
           ) == nil
  end

  test "Complete sequence variants, one word in dictionary" do
    assert Doublets.Solver.complete_seq_variants(["head", "heal", "teal", "tell", "tall", "call"]) ==
             [["head", "heal", "teal", "tell", "tall", "call", "fall"]]
  end

  test "Complete sequence variants, multiple words in dictionary" do
    assert Doublets.Solver.complete_seq_variants(["head", "heal", "teal", "tell", "tall"]) ==
             [
               ["head", "heal", "teal", "tell", "tall", "fall"],
               ["head", "heal", "teal", "tell", "tall", "call"],
               ["head", "heal", "teal", "tell", "tall", "tail"]
             ]
  end

  test "Complete sequence variants, no words in dictionary" do
    assert Doublets.Solver.complete_seq_variants([
             "head",
             "heal",
             "teal",
             "tell",
             "tall",
             "call",
             "fall"
           ]) ==
             []
  end

  test "Find variants, one word in dictionary" do
    assert Doublets.Solver.find_variants("tail") == ["tall"]
  end

  test "Find variants, multiple words in dictionary" do
    assert Doublets.Solver.find_variants("tall") == ["fall", "call", "tell", "tail"]
  end

  test "Find variatns, no words in dictionary" do
    assert Doublets.Solver.find_variants("ceil") == []
    assert Doublets.Solver.find_variants("word") == []
  end

  test "Get words with same length" do
    assert Doublets.Solver.same_length_words("ceil") ==
             [
               "muta",
               "fall",
               "call",
               "task",
               "quat",
               "head",
               "heal",
               "teal",
               "tell",
               "tall",
               "tail",
               "door",
               "boor",
               "book",
               "look",
               "lock",
               "bank",
               "bonk",
               "loon",
               "loan"
             ]

    assert Doublets.Solver.same_length_words("fizzbuzz") ==
             [
               "tunnland",
               "trewsman",
               "leisured",
               "expedite",
               "wartweed",
               "atreptic",
               "canonist",
               "bushveld",
               "kipperer",
               "kitthoge",
               "wardmaid",
               "jubilist",
               "surmount",
               "weakfish",
               "playwork"
             ]
  end

  test "Distance between two words" do
    assert Doublets.Solver.distance("tell", "tall") == 1
    assert Doublets.Solver.distance("tell", "team") == 2
    assert Doublets.Solver.distance("tell", "scream") == 4
  end

  test "Get the last word of a list" do
    assert Doublets.Solver.last_word(["fall", "call", "tell", "tail"]) == "tail"
    assert Doublets.Solver.last_word(["tail"]) == "tail"
  end
end
