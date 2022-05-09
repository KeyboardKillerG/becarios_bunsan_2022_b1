defmodule Doublets.Solver do
  @moduledoc """
  This module provides funtions to solve 'Doublets' puzzle.
  The puzzle is to take two words of the same length and find a way of linking the first word to the second word by only changing one letter at a time. At the end of the transformation, there will be a collections of words that show the beginning word being changed into the ending word, one letter at a time.
  """
  @words "./resources/words.txt"
         |> File.read!()
         |> String.split("\n")

  def doublets(word_1, word_2) do
    doublets_impl([[word_1]], word_2)
  end

  def doublets_impl([], _word_2), do: []

  def doublets_impl(word_seqs, word_2) do
    seqs_variants = Enum.flat_map(word_seqs, fn seq -> complete_seq_variants(seq) end)

    case find_solution(seqs_variants, word_2) do
      nil -> doublets_impl(seqs_variants, word_2)
      sol -> sol
    end
  end

  def find_solution(word_seqs, target) do
    Enum.find(word_seqs, fn seq -> last_word(seq) == target end)
  end

  def complete_seq_variants(word_seq) do
    variants =
      word_seq
      |> last_word()
      |> find_variants()
      |> Enum.filter(fn w -> w not in word_seq end)

    for v <- variants, do: word_seq ++ [v]
  end

  def find_variants(word) do
    word
    |> same_length_words()
    |> Enum.filter(fn w -> distance(word, w) == 1 end)
  end

  def same_length_words(word) do
    @words
    |> Enum.filter(fn w -> String.length(w) == String.length(word) end)
    |> List.delete(word)
  end

  def distance(word_1, word_2) do
    letters_1 = String.graphemes(word_1)
    letters_2 = String.graphemes(word_2)

    Enum.zip_with(letters_1, letters_2, fn a, b -> a == b end)
    |> Enum.count(&(not &1))
  end

  def last_word(word_seq), do: Enum.at(word_seq, -1)
end
