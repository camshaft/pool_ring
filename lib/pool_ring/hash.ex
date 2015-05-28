defmodule PoolRing.Hash do
  @first 12 * 8
  @second 8 * 8

  def hash(init, ring_size, preflist_size) do
    {preflist, _} = Enum.map_reduce(0..(preflist_size - 1), init, fn(_, info) ->
      perform(info, ring_size)
    end)
    preflist
  end

  defp perform(info, ring_size) do
    prev = <<_ :: size(@first), num :: size(@second)>> = :crypto.hash(:sha, [info])
    {rem(num, ring_size), prev}
  end
end