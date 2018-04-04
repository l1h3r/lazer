defmodule Lazer.Diff do
  @moduledoc false
  alias Lazer.Diff

  @enforce_keys ~w(kind)a

  defstruct ~w(kind path lhs rhs index item)a

  @typedoc """
  The kind of change; will be one of the following:
    I - indicates a newly inserted element
    D - indicates a deleted element
    M - indicates a modified element
    L - indicates a change to a list element
    Noop - indicates no change
  """
  @type kind :: :I | :D | :M | :L | :Noop

  @type t :: %Diff{
          # Indicates the kind of change. See `kind/0`
          kind: atom,
          # The element path (from left-to-right)
          path: list | nil,
          # The left-hand-side value of the comparison
          lhs: any | nil,
          # The right-hand-side value of the comparison
          rhs: any | nil,
          # Indicates the list index of the change, if kind is :L
          index: integer | nil,
          # Contains the record indicating the list change, if kind is :L
          item: t | nil
        }

  @doc false
  def new(:I, path, {_, rhs}), do: %Diff{kind: :I, path: path, rhs: rhs}
  def new(:D, path, {lhs, _}), do: %Diff{kind: :D, path: path, lhs: lhs}
  def new(:M, path, {lhs, rhs}), do: %Diff{kind: :M, path: path, lhs: lhs, rhs: rhs}
  def new(:L, path, {index, item}), do: %Diff{kind: :L, path: path, index: index, item: item}
  def new(:Noop, path, {lhs, rhs}), do: %Diff{kind: :Noop, path: path, lhs: lhs, rhs: rhs}

  @doc false
  def blank?(%Diff{kind: :Noop}), do: true
  def blank?(%Diff{kind: :L, item: %Diff{kind: :Noop}}), do: true
  def blank?(%Diff{}), do: false
end
