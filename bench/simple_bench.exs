defmodule SimpleBench do
  use Benchfella

  @lhs Enum.to_list(1..1000)
  @rhs Enum.to_list(1..1000)

  bench "simple" do
    Lazer.diff(@lhs, @rhs)
  end
end
