defmodule GenBuffer do
  use GenServer

  @latency 50

  def start(mergefun, flushfun) do
    GenServer.start(__MODULE__, {mergefun, flushfun})
  end

  def start_link(mergefun, flushfun) do
    GenServer.start_link(__MODULE__, {mergefun, flushfun})
  end

  def enqueue(buffer, cmd) do
    GenServer.call(buffer, {:enqueue, cmd})
  end

  @enforce_keys [:mergefun, :flushfun]
  defstruct [
    busy?: false,
    buffer: nil,
    timer: nil,
    flushfun: nil,
    mergefun: nil
  ]

  @impl true
  def init({mergefun, flushfun}) do
    {:ok, %GenBuffer{
      flushfun: flushfun,
      mergefun: mergefun
    }}
  end

  @impl true
  def handle_call({:enqueue, cmd}, _from, state) do
    {:reply, :ok, handle_enqueue(cmd, state)}
  end

  @impl true
  def handle_info(:flush, state) do
    state = %GenBuffer{state | timer: nil}
    {:noreply, flush(state)}
  end
  def handle_info({:ready, ref}, state = %GenBuffer{busy?: ref}) do
    state = %GenBuffer{state | busy?: false}
    if state.buffer do
      {:noreply, start_timer(state)}
    else
      {:noreply, state}
    end
  end

  defp handle_enqueue(cmd, state) do
    buffer = state.mergefun.(state.buffer, cmd)
    state = %GenBuffer{state | buffer: buffer}
    cond do
      state.busy? ->
        state
      state.timer ->
        state
      true ->
        start_timer(state)
    end
  end

  defp start_timer(state) do
    timer = Process.send_after(self(), :flush, @latency)
    %GenBuffer{state | timer: timer}
  end

  defp flush(state) do
    ref = state.flushfun.(state.buffer)
    %GenBuffer{state | buffer: nil, busy?: ref}
  end

end
