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
      [%Lazer.Diff{kind: :A, path: [:a], rhs: 2}]

      iex> Lazer.diff(%{a: 3}, %{a: 2})
      [%Lazer.Diff{kind: :E, lhs: 3, path: [:a], rhs: 2}]

      iex> Lazer.diff(%{a: 3}, %{a: %{}})
      [%Lazer.Diff{kind: :E, lhs: 3, path: [:a], rhs: %{}}]

      iex> Lazer.diff(%{a: %{}}, %{a: %{b: 1}})
      [%Lazer.Diff{kind: :A, path: [:a, :b], rhs: 1}]

      iex> foo = %{a: 1, b: 2, c: %{d: 3, e: 4, f: 5}}
      iex> bar = %{a: 1, b: 42, c: %{d: %{something_else: "entirely"}, f: 10}}
      iex> Lazer.diff(foo, bar)
      [
        %Lazer.Diff{kind: :E, lhs: 5, path: [:c, :f], rhs: 10},
        %Lazer.Diff{kind: :D, lhs: 4, path: [:c, :e]},
        %Lazer.Diff{kind: :E, lhs: 3, path: [:c, :d], rhs: %{something_else: "entirely"}},
        %Lazer.Diff{kind: :E, lhs: 2, path: [:b], rhs: 42}
      ]

  ## Options

      iex> Lazer.diff(%{a: 1}, %{a: 1}, noops: true)
      [%Lazer.Diff{kind: :N, lhs: %{a: 1}, path: [], rhs: %{a: 1}}]

  """
  @spec diff(lhs :: any, rhs :: any, opts :: keyword) :: Diff.t() | [Diff.t()]
  def diff(lhs, rhs, opts \\ []) do
    lhs
    |> do_diff(rhs, [])
    |> List.wrap()
    |> List.flatten()
    |> format_changes(opts)
  end

  defp do_diff(lhs, lhs, path) do
    Diff.new(:N, path, {lhs, lhs})
  end

  defp do_diff(lhs, rhs, path) when is_list(lhs) and is_list(rhs) do
    lhs
    |> Enum.count()
    |> max(Enum.count(rhs))
    |> Range.new(0)
    |> reduce_diff({lhs, rhs, path})
  end

  defp do_diff(%{} = lhs, %{} = rhs, path) do
    lhs
    |> Map.keys()
    |> Enum.concat(Map.keys(rhs))
    |> Enum.uniq()
    |> reduce_diff({lhs, rhs, path})
  end

  defp do_diff(lhs, rhs, path) when is_nil(lhs) and not is_nil(rhs) do
    Diff.new(:A, path, {lhs, rhs})
  end

  defp do_diff(lhs, rhs, path) when is_nil(rhs) and not is_nil(lhs) do
    Diff.new(:D, path, {lhs, rhs})
  end

  defp do_diff(lhs, rhs, path) when lhs !== rhs do
    Diff.new(:E, path, {lhs, rhs})
  end

  @spec apply(target :: map | list, changes :: [Diff.t()]) :: map | list
  def apply(target, changes) when is_list(changes) do
    Enum.reduce(changes, target, &do_apply(&2, &1))
  end

  defp do_apply(target, %Diff{kind: :A, path: path, rhs: rhs}) do
    put_in(target, accessor(path), rhs)
  end

  defp do_apply(target, %Diff{kind: :E, path: path, rhs: rhs}) do
    update_in(target, accessor(path, :edit), fn _ -> rhs end)
  end

  defp do_apply(target, %Diff{kind: :D, path: path}) do
    elem(pop_in(target, accessor(path, :remove)), 1)
  end

  defp do_apply(target, %Diff{kind: :N}), do: target

  # def revert(target, changes) do
  #   target
  # end

  def observe(lhs, rhs, fun) do
    lhs
    |> diff(rhs)
    |> List.foldr([], fn diff, acc ->
      case fun.(diff) do
        :ok -> [diff | acc]
        :skip -> acc
      end
    end)
  end

  defp reduce_diff(keys, {lhs, rhs, path}) do
    Enum.reduce(keys, [], fn key, acc ->
      diff =
        do_diff(
          get_in(lhs, accessor(key)),
          get_in(rhs, accessor(key)),
          Enum.concat(path, [key])
        )

      [diff | acc]
    end)
  end

  @spec format_changes(changes :: [Diff.t()], opts :: keyword) :: [Diff.t()]
  defp format_changes(changes, opts) do
    if Keyword.get(opts, :noops, false) do
      changes
    else
      Enum.reject(changes, &Diff.blank?/1)
    end
  end

  defp accessor(path, type \\ :add) do
    path
    |> List.wrap()
    |> Enum.map(fn key ->
      fn
        :get, %{} = data, next ->
          next.(Map.get(data, key))

        :get, data, next when is_list(data) ->
          next.(Enum.at(data, key))

        :get_and_update, %{} = data, next ->
          data
          |> Map.get(key)
          |> next.()
          |> case do
            {got, update} ->
              {got, Map.put(data, key, update)}

            :pop ->
              {:pop, Map.delete(data, key)}
          end

        :get_and_update, data, next when is_list(data) ->
          data
          |> Enum.at(key)
          |> next.()
          |> case do
            {got, update} when type === :add ->
              {[got], List.insert_at(data, key, update)}

            {got, update} when type === :edit ->
              {[got], List.replace_at(data, key, update)}

            :pop ->
              {:pop, List.delete_at(data, key)}
          end
      end
    end)
  end
end
