defmodule Milight.Queue do
  alias Milight.Queue
  alias Milight.Command
  require Logger
  use GenServer

  @latency 50

  def start_link(channel) do
    GenServer.start_link(__MODULE__, channel)
  end

  def enqueue(queue, cmd) do
    GenServer.call(queue, {:enqueue, cmd})
  end

  @enforce_keys [:channel]
  defstruct [
    channel: nil,
    busy?: false,
    queue: [],
    timer: nil
  ]

  @impl true
  def init(channel) do
    {:ok, %Queue{channel: channel}}
  end

  @impl true
  def handle_call({:enqueue, cmd}, _from, state) do
    {:reply, :ok, handle_enqueue(cmd, state)}
  end

  @impl true
  def handle_info(:flush, state) do
    state = %Queue{state | timer: nil}
    {:noreply, flush(state)}
  end
  def handle_info({:ready, ref}, state = %Queue{busy?: ref}) do
    state = %Queue{state | busy?: false}
    if Enum.empty? state.queue do
      {:noreply, state}
    else
      {:noreply, start_timer(state)}
    end
  end

  defp handle_enqueue(cmd, state) do
    Logger.debug("[queue] enqueue: #{inspect(cmd)}")
    queue = merge_command(cmd, state.queue)
    state = %Queue{state | queue: queue}
    Logger.debug("[queue] queue now: #{inspect(queue)}")
    cond do
      state.busy? ->
        state
      state.timer ->
        state
      true ->
        start_timer(state)
    end
  end

  defp merge_command(cmd, queue = [head | rest]) do
    head = Command.Mergeable.merge(cmd, head)
    if head do
      merge_command(head, rest)
    else
      [cmd | queue]
    end
  end
  defp merge_command(cmd, []) do
    [cmd]
  end

  defp start_timer(state) do
    timer = Process.send_after(self(), :flush, @latency)
    %Queue{state | timer: timer}
  end

  defp flush(state) do
    queue = state.queue
      |> Enum.reverse()
      |> Enum.flat_map(&Command.Encodable.encode/1)
    ref = Milight.Channel.send(state.channel, queue)
    %Queue{state | queue: [], busy?: ref}
  end

end
