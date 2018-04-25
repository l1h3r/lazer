defmodule LazerTest do
  use ExUnit.Case, async: true
  doctest Lazer
  alias Lazer.Diff

  describe "maps" do
    test "no changes" do
      changes = Lazer.diff(%{a: 1, b: [1, 2, 3]}, %{a: 1, b: [1, 2, 3]})

      assert changes === []
    end

    test "no changes - opts.noops" do
      changes = Lazer.diff(%{a: 1, b: 2}, %{a: 1, b: 2}, noops: true)

      assert changes === [
               %Diff{kind: :N, path: [], lhs: %{a: 1, b: 2}, rhs: %{a: 1, b: 2}}
             ]
    end

    test "single addition" do
      changes = Lazer.diff(%{}, %{a: 1})

      assert changes === [%Diff{kind: :A, path: [:a], rhs: 1}]
    end

    test "single removal" do
      changes = Lazer.diff(%{a: 1, b: 2}, %{a: 1})

      assert changes === [%Diff{kind: :D, path: [:b], lhs: 2}]
    end
  end

  describe "lists" do
    test "no changes" do
      changes = Lazer.diff([1, 2, 3], [1, 2, 3])

      assert changes === []
    end

    test "no changes - opts.noops" do
      changes = Lazer.diff([1, 2, 3], [1, 2, 3], noops: true)

      assert changes === [
               %Diff{kind: :N, path: [], lhs: [1, 2, 3], rhs: [1, 2, 3]}
             ]
    end

    test "single addition" do
      changes = Lazer.diff([1, 2, 3], [1, 2, 3, 4])

      assert changes === [%Diff{kind: :A, path: [3], rhs: 4}]
    end

    test "single removal" do
      changes = Lazer.diff([1, 2, 3], [1, 2])

      assert changes === [%Diff{kind: :D, path: [2], lhs: 3}]
    end

    test "single edit - last index" do
      changes = Lazer.diff([1, 2, 3], [1, 2, 4])

      assert changes === [%Diff{kind: :E, path: [2], lhs: 3, rhs: 4}]
    end

    test "single edit - middle index" do
      changes = Lazer.diff([1, 2, 3, 4], [1, 5, 6, 4])

      assert changes === [
               %Diff{kind: :E, path: [1], lhs: 2, rhs: 5},
               %Diff{kind: :E, path: [2], lhs: 3, rhs: 6}
             ]
    end

    test "complex" do
      lhs = %{a: [4, 18, -4, 18, 3]}
      rhs = %{a: [20, -3, 9, -12, 16, 11, 6, -8, -18, 7, -4]}

      changes = Lazer.diff(lhs, rhs)

      assert changes === [
               %Diff{kind: :E, path: [:a, 0], lhs: 4, rhs: 20},
               %Diff{kind: :E, path: [:a, 1], lhs: 18, rhs: -3},
               %Diff{kind: :E, path: [:a, 2], lhs: -4, rhs: 9},
               %Diff{kind: :E, path: [:a, 3], lhs: 18, rhs: -12},
               %Diff{kind: :E, path: [:a, 4], lhs: 3, rhs: 16},
               %Diff{kind: :A, path: [:a, 5], rhs: 11},
               %Diff{kind: :A, path: [:a, 6], rhs: 6},
               %Diff{kind: :A, path: [:a, 7], rhs: -8},
               %Diff{kind: :A, path: [:a, 8], rhs: -18},
               %Diff{kind: :A, path: [:a, 9], rhs: 7},
               %Diff{kind: :A, path: [:a, 10], rhs: -4}
             ]
    end

    test "applies changes" do
      lhs = [1, 2, 3, 4]
      rhs = [1, 5, 6, 4, 8]

      changes = Lazer.diff(lhs, rhs)
      assert Lazer.apply(lhs, changes) === rhs
    end
  end
end
