defmodule Milight.Channel do
  use GenServer
  require Logger

  @default_address {127, 0, 0, 1}
  @default_port 8899

  @enforce_keys [:socket]
  defstruct socket: nil, endpoint: {@default_address, @default_port}

  def start_link(endpoint) do
    GenServer.start_link(__MODULE__, prepare_endpoint(endpoint))
  end

  @spec send(atom | pid, [Milight.Command.t]) :: reference
  def send(channel, queue) do
    ref = Kernel.make_ref()
    :ok = GenServer.cast(channel, {:send, ref, queue, self()})
    ref
  end

  @impl true
  def init(endpoint) do
    {:ok, sock} = :gen_udp.open(0)
    {:ok, %__MODULE__{
      socket: sock,
      endpoint: endpoint
    }}
  end

  @impl true
  def handle_cast({:send, ref, queue, requester}, state) do
    Logger.debug("[channel] command queue: #{inspect(queue)}")
    Enum.each(queue, &handle_command(&1, state))
    Kernel.send(requester, {:ready, ref})
    {:noreply, state}
  end

  defp handle_command({:packet, bytes}, state = %__MODULE__{}) do
    :gen_udp.send(state.socket, state.endpoint, bytes)
  end
  defp handle_command({:delay, ms}, _state) do
    Process.sleep(ms)
  end

  defp prepare_endpoint({addr, port}) when is_integer(port) do
    {Milight.Address.resolve(addr), port}
  end
  defp prepare_endpoint(addr) do
    {Milight.Address.resolve(addr), @default_port}
  end

end
