import Config

config :milightdash, Milight.Dash.Server,
  adapter: Plug.Cowboy,
  plug: Milight.Dash.API,
  scheme: :http,
  port: 8880

config :milightdash,
  maru_servers: [Milight.Dash.Server]

config :logger, :console,
  metadata: [:request_id]
