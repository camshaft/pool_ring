defmodule PoolRing do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec

    options  = [ strategy: :one_for_one, name: PoolRing.Supervisor ]
    children = [
      worker(PoolRing.Server, [])
    ]

    Supervisor.start_link(children, options)
  end

  def start(name, ring_size, node_fn) do
    PoolRing.Server.start(name, ring_size, node_fn)
  end

  def get(ring, info, preflist_size \\ 1) do
    {:ok, ring_size} = PoolRing.Server.ring_size(ring)
    preflist = PoolRing.Hash.hash(info, ring_size, preflist_size)
    case PoolRing.Server.from_preflist(ring, preflist) do
      [] when preflist_size == 1 ->
        {:error, :no_connections}
      [pid | _] when preflist_size == 1 ->
        {:ok, pid}
      pids ->
        pids
    end
  end
end
