defmodule Lazer.Diff do
  @moduledoc false
  alias Lazer.Diff

  @enforce_keys ~w(kind)a

  defstruct ~w(kind path lhs rhs index item)a

  @typedoc """
  The kind of change; will be one of the following:
    A - indicates an element was added
    D - indicates an element was removed
    E - indicates a change to an element
    N - indicates no change
  """
  @type kind :: :A | :D | :E | :N

  @type t :: %Diff{
          # Indicates the kind of change
          kind: atom,
          # The element path (from left-to-right)
          path: list,
          # The left-hand-side value of the comparison
          lhs: any | nil,
          # The right-hand-side value of the comparison
          rhs: any | nil
        }

  @doc false
  def new(:A, path, {_, rhs}), do: %Diff{kind: :A, path: path, rhs: rhs}
  def new(:D, path, {lhs, _}), do: %Diff{kind: :D, path: path, lhs: lhs}
  def new(:E, path, {lhs, rhs}), do: %Diff{kind: :E, path: path, lhs: lhs, rhs: rhs}
  def new(:N, path, {lhs, rhs}), do: %Diff{kind: :N, path: path, lhs: lhs, rhs: rhs}

  @doc false
  def blank?(%Diff{kind: :N}), do: true
  def blank?(%Diff{}), do: false
end

defimpl Inspect, for: Lazer.Diff do
  import Inspect.Algebra

  def inspect(diff, opts) do
    doc =
      diff
      |> sanitize()
      |> to_doc(opts)

    concat(["#Lazer.Diff<", doc, ">"])
  end

  defp sanitize(diff) do
    diff
    |> Map.from_struct()
    |> Enum.reduce([], fn
      {_, nil}, acc -> acc
      {key, value}, acc -> [{key, value} | acc]
    end)
    |> Enum.reverse()
  end
end
