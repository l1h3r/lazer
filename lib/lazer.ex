defmodule Lazer do
  @moduledoc """
  Documentation for Lazer.
  """
  alias Lazer.Diff

  @type subject :: {lhs :: any, rhs :: any, path :: list | nil}

  @doc """
  Returns the diff between two Elixir data types

  ## Examples

      iex> Lazer.diff(%{a: 1}, %{a: 1})
      []

      iex> Lazer.diff(%{a: 1}, %{})
      [%Lazer.Diff{kind: :D, lhs: 1, path: [:a]}]

      iex> Lazer.diff(%{}, %{a: 2})
      [%Lazer.Diff{kind: :I, path: [:a], rhs: 2}]

      iex> Lazer.diff(%{a: 3}, %{a: 2})
      [%Lazer.Diff{kind: :M, lhs: 3, path: [:a], rhs: 2}]

      iex> Lazer.diff(%{a: 3}, %{a: %{}})
      [%Lazer.Diff{kind: :M, lhs: 3, path: [:a], rhs: %{}}]

      iex> Lazer.diff(%{a: %{}}, %{a: %{b: 1}})
      [%Lazer.Diff{kind: :I, path: [:a, :b], rhs: 1}]

      iex> foo = %{a: 1, b: 2, c: %{d: 3, e: 4, f: 5}}
      iex> bar = %{a: 1, b: 42, c: %{d: %{something_else: "entirely"}, f: 10}}
      iex> Lazer.diff(foo, bar)
      [
        %Lazer.Diff{kind: :M, lhs: 5, path: [:c, :f], rhs: 10},
        %Lazer.Diff{kind: :D, lhs: 4, path: [:c, :e]},
        %Lazer.Diff{kind: :M, lhs: 3, path: [:c, :d], rhs: %{something_else: "entirely"}},
        %Lazer.Diff{kind: :M, lhs: 2, path: [:b], rhs: 42}
      ]

  ## Options

      iex> Lazer.diff(%{a: 1}, %{a: 1}, noops: true)
      [%Lazer.Diff{kind: :Noop, lhs: %{a: 1}, rhs: %{a: 1}}]

  """
  @spec diff(lhs :: any, rhs :: any, opts :: keyword) :: Diff.t() | [Diff.t()]
  def diff(%{} = map1, %{} = map2, opts \\ []) do
    map1
    |> deep_diff(map2)
    |> List.wrap()
    |> List.flatten()
    |> filter_changes(opts)
  end

  defp deep_diff(_, _, _ \\ nil)
  defp deep_diff(lhs, lhs, _), do: Diff.new(:Noop, nil, {lhs, lhs})

  defp deep_diff(lhs, rhs, path) when is_list(lhs) and is_list(rhs),
    do: do_diff(:list, {lhs, rhs, path})

  defp deep_diff(%{} = lhs, %{} = rhs, path), do: do_diff(:map, {lhs, rhs, path})
  defp deep_diff(lhs, rhs, path), do: do_diff(:default, {lhs, rhs, path})

  @spec insert?(lhs :: any, rhs :: any) :: boolean
  defp insert?(lhs, rhs), do: is_nil(lhs) and not is_nil(rhs)

  @spec delete?(lhs :: any, rhs :: any) :: boolean
  defp delete?(lhs, rhs), do: is_nil(rhs) and not is_nil(lhs)

  @spec modify?(lhs :: any, rhs :: any) :: boolean
  defp modify?(lhs, rhs), do: lhs !== rhs

  @spec do_diff(type :: atom, subject :: subject) :: Diff.t() | [Diff.t()] | no_return
  defp do_diff(:default, {lhs, rhs, path}) do
    cond do
      insert?(lhs, rhs) -> Diff.new(:I, path, {lhs, rhs})
      delete?(lhs, rhs) -> Diff.new(:D, path, {lhs, rhs})
      modify?(lhs, rhs) -> Diff.new(:M, path, {lhs, rhs})
      true -> raise RuntimeError, "I don't know this ditty"
    end
  end

  defp do_diff(:map, {lhs, rhs, path}) do
    lhs
    |> Map.keys()
    |> Enum.concat(Map.keys(rhs))
    |> Enum.uniq()
    |> Enum.reduce([], fn key, acc ->
      collect_diff(
        Map.get(lhs, key),
        Map.get(rhs, key),
        concat_path(path, key),
        acc
      )
    end)
  end

  defp do_diff(:list, {lhs, rhs, path}) do
    lhs
    |> Enum.count()
    |> max(Enum.count(rhs))
    |> Range.new(0)
    |> Enum.reduce([], fn index, acc ->
      collect_diff(
        Enum.at(lhs, index),
        Enum.at(rhs, index),
        concat_path(path, index),
        acc
      )
    end)
  end

  @spec filter_changes(changes :: [Diff.t()], opts :: keyword) :: [Diff.t()]
  defp filter_changes(changes, opts) do
    if Keyword.get(opts, :noops, false) do
      changes
    else
      Enum.reject(changes, &Diff.blank?/1)
    end
  end

  @spec collect_diff(lhs :: any, rhs :: any, path :: list, acc :: list) :: list
  defp collect_diff(lhs, rhs, path, acc), do: [deep_diff(lhs, rhs, path) | acc]

  @spec concat_path(path :: list | nil, key :: any) :: [any]
  defp concat_path(nil, key), do: List.wrap(key)
  defp concat_path(path, key), do: Enum.concat(path, List.wrap(key))
end
