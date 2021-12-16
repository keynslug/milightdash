defmodule Milight.Dash do

defmodule Server do
  use Maru.Server, otp_app: :milightdash
end

defmodule Router do
  use Server

  get do
    json(conn, %{blarg: __MODULE__})
  end
end

defmodule API do
  use Server
  require Logger

  before do
    plug Plug.Logger
    plug Plug.RequestId
  end

  plug Plug.Parsers,
    parsers: [:urlencoded, {:json, json_decoder: Jason}]

  mount Router

  rescue_from :all, as: e do
    Logger.info("exception: #{inspect(e)}")
    conn |> put_status(Plug.Exception.status(e)) |> text("#{inspect(e)}")
  end
end

end
