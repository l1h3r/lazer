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
