defmodule Milight.Light.RGBW do
  alias Milight.Light.RGBW

  @type t :: %RGBW{}
  @type command :: :on | :off | {:hue, float} | {:brightness, float}
  @type group :: 1..4

  defstruct c: :on, group: nil

  def on(), do: %RGBW{c: :on}
  def off(), do: %RGBW{c: :off}

  def hue(v) when v >= 0.0 and v <= 1.0 do
    %RGBW{c: {:hue, v}}
  end

  def brightness(v) when v >= 0.0 and v <= 1.0 do
    %RGBW{c: {:brightness, v}}
  end

  def group(cmd, group) when group in 1..4 do
    %RGBW{cmd | group: group}
  end

  defimpl Milight.Command.Encodable do
    import Milight.Command

    @spec encode(RGBW.t) :: [Encodable.code]
    def encode(%RGBW{c: c, group: g}), do: encode(c, g)

    defp encode(:on, nil), do: [packet(0x42, 0x00), delay()]
    defp encode(:on, 1), do: [packet(0x45, 0x00), delay()]
    defp encode(:on, 2), do: [packet(0x47, 0x00), delay()]
    defp encode(:on, 3), do: [packet(0x49, 0x00), delay()]
    defp encode(:on, 4), do: [packet(0x4b, 0x00), delay()]

    defp encode(:off, nil), do: [packet(0x41, 0x00)]
    defp encode(:off, 1), do: [packet(0x46, 0x00)]
    defp encode(:off, 2), do: [packet(0x48, 0x00)]
    defp encode(:off, 3), do: [packet(0x4a, 0x00)]
    defp encode(:off, 4), do: [packet(0x4c, 0x00)]

    defp encode({:hue, v}, group) do
      encode(:on, group) ++ [packet(0x40, encode_hue(v))]
    end

    defp encode({:brightness, v}, group) do
      encode(:on, group) ++ [packet(0x4e, encode_brightness(v))]
    end

    @spec encode_hue(float) :: byte
    defp encode_hue(v) do
      v = (1.0 - v) + (2 / 3)
      v = if v > 1.0, do: v - 1.0, else: v
      trunc(v * 256)
    end

    @spec encode_brightness(float) :: byte
    defp encode_brightness(v) do
      trunc(v * 25) + 2
    end
  end

  defimpl Milight.Command.Mergeable do

    @spec merge(RGBW.t, RGBW.t) :: RGBW.t | false
    def merge(%RGBW{c: lhs, group: g}, %RGBW{c: rhs, group: g}) do
      if c = merge_command(lhs, rhs) do
        %RGBW{c: c, group: g}
      else
        false
      end
    end
    def merge(_, _) do
      false
    end

    defp merge_command(:on = lhs, :off), do: lhs
    defp merge_command(:off = lhs, :on), do: lhs
    defp merge_command(:on, {c, _} = rhs) when c in [:hue, :brightness], do: rhs
    defp merge_command({c, _} = lhs, {c, _}) when c in [:hue, :brightness], do: lhs
    defp merge_command({c, _} = lhs, :on) when c in [:hue, :brightness], do: lhs
    defp merge_command(_, _), do: false

  end

end
