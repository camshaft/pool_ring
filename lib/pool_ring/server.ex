defmodule PoolRing.Server do
  use GenServer

  @ring_sizes :pool_ring_sizes
  @refs :poll_ring_refs

  def start_link() do
    GenServer.start_link(__MODULE__, [], [name: __MODULE__])
  end

  def start(name, ring_size, node_fn) do
    GenServer.call(__MODULE__, {:start, name, ring_size, node_fn})
  end

  def ring_size(name) do
    case :ets.lookup(@ring_sizes, name) do
      [] ->
        {:error, :not_started}
      [{^name, size}] ->
        {:ok, size}
    end
  end

  def from_preflist(name, preflist) do
    Enum.map(preflist, fn(index) ->
      :ets.lookup_element(name, index, 2)
    end) |> Enum.filter(fn
      (pid) when is_pid(pid) ->
        case :erlang.process_info(pid, :status) do
          :undefined ->
            false
          _ ->
            true
        end
      (_) ->
        false
    end)
  end

  def init(_) do
    :ets.new(@ring_sizes, [{:read_concurrency, true}, :named_table, :set])
    :ets.new(@refs, [{:read_concurrency, true}, :named_table, :set])
    :erlang.process_flag(:trap_exit, true)
    {:ok, HashDict.new}
  end

  def handle_call({:start, name, ring_size, node_fn}, _from, state) do
    try do
      pids = start_pool(name, ring_size, node_fn)
  
      :ets.new(name, [{:read_concurrency, true},
                       :named_table,
                       :set])
      :ets.insert(name, pids)

      :ets.insert(@ring_sizes, {name, ring_size})
      state = Dict.put(state, name, node_fn)

      {:reply, :ok, state}
    catch
      e ->
        {:reply, e, state}
    end
  end

  def handle_cast(_, state) do
    {:noreply, state}
  end

  def handle_info({:DOWN, ref, _type, _object, _info}, state) do
    {index, ring, node_fn} = :ets.lookup_element(@refs, ref, 2)
    :ets.delete(@refs, ref)
    :timer.send_after(1000, {:reconnect, index, ring, node_fn, 1000})
    {:noreply, state}
  end
  def handle_info({:reconnect, index, ring, node_fn, timeout}, state) do
    pid = start_pid(index, nil, ring, node_fn)
    :ets.insert(ring, pid)
    {:noreply, state}
  rescue
    _ ->
      :timer.send_after(timeout, {:reconnect, index, ring, node_fn, min(timeout * 2, 30_000)})
      {:noreply, state}
  end
  def handle_info(_, state) do
    {:noreply, state}
  end

  defp start_pool(name, ring_size, node_fn) do
    Enum.map(0..(ring_size - 1), &start_pid(&1, nil, name, node_fn))
  end

  defp start_pid(index, prev, name, node_fn) do
    {:ok, pid} = exec(node_fn, index, prev)
    ref = :erlang.monitor(:process, pid)
    :ets.insert(@refs, {ref, {index, name, node_fn}})
    {index, pid}
  end

  defp exec(node_fn, index, prev) when is_function(node_fn) do
    node_fn.(index, prev)
  end
  defp exec({mod, fun}, index, prev) do
    apply(mod, fun, [index, prev])
  end
  defp exec({mod, fun, args}, index, prev) do
    apply(mod, fun, args ++ [index, prev])
  end

end