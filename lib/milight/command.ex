defmodule Milight.Command do

  @spec packet(binary) :: Encodable.code
  def packet(bytes) when is_binary(bytes), do: {:packet, bytes}

  @spec packet(byte, byte) :: Encodable.code
  def packet(b1, b2), do: {:packet, <<b1, b2>>}

  @spec delay() :: Encodable.code
  def delay(), do: {:delay, 100}

  @spec delay(non_neg_integer()) :: Encodable.code
  def delay(ms), do: {:delay, ms}

  defprotocol Encodable do
    @type code :: {:packet, binary()} | {:delay, non_neg_integer()}
    @spec encode(t) :: list(code)
    def encode(command)
  end

  defprotocol Mergeable do
    @spec merge(t, t) :: t | false
    def merge(command, command)
  end

end
