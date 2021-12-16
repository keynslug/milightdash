defmodule Milight.Address do

  @type addr :: :inet.ip_address

  defmodule BadAddressError do
    defexception [:address]

    @impl true
    @spec message(%__MODULE__{}) :: String.t
    def message(exception) do
      "expected an IP address, got: #{inspect(exception.address)}"
    end
  end

  defmodule ResolveError do
    defexception [:hostname, :reason]

    @impl true
    @spec message(%__MODULE__{}) :: String.t
    def message(exception) do
      "failed to resolve hostname #{exception.hostname}, reason: #{inspect(exception.reason)}"
    end
  end

  @spec resolve(binary | charlist | addr) :: addr
  def resolve(addr = {a, b, c, d}) when
    a in 0..255 and
    b in 0..255 and
    c in 0..255 and
    d in 0..255
  do
    addr
  end

  def resolve(addr = {a, b, c, d, e, f, g, h}) when
    a in 0..0xffff and
    b in 0..0xffff and
    c in 0..0xffff and
    d in 0..0xffff and
    e in 0..0xffff and
    f in 0..0xffff and
    g in 0..0xffff and
    h in 0..0xffff
  do
    addr
  end

  def resolve(addr) when is_binary(addr) do
    addr |> String.to_charlist() |> resolve()
  end

  def resolve(addr) when is_list(addr) do
    case :inet.parse_address(addr) do
      {:ok, addr} -> addr
      {:error, _} -> resolve_hostname(addr, [:inet, :inet6])
    end
  end

  def resolve(addr) do
    raise BadAddressError, address: addr
  end

  defp resolve_hostname(hostname, [family | rest]) do
    case :inet.getaddr(hostname, family) do
      {:ok, addr} ->
        addr
      {:error, :nxdomain} ->
        resolve_hostname(hostname, rest)
      {:error, :einval} ->
        raise BadAddressError, address: hostname
      {:error, reason} ->
        raise ResolveError, hostname: hostname, reason: reason
      end
    end

    defp resolve_hostname(hostname, []) do
      raise ResolveError, hostname: hostname, reason: :nxdomain
    end

end
