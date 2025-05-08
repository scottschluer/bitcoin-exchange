# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :bitcoin_exchange,
  generators: [timestamp_type: :utc_datetime],
  
  # Wallet configuration
  wallet: [
    initial_balance: 10_000,
    initial_bitcoin_balance: 0,
    pubsub_topic: "wallet_updates",
    genserver_timeout: 30_000
  ],
  
  # Price tracker configuration
  price_tracker: [
    update_interval: 60_000,
    initial_update_delay: 2_000,
    max_backoff_interval: 1_800_000,
    bitcoin_id: 1,
    cache_valid_seconds: 3600,
    pubsub_topic: "price_updates",
    genserver_timeout: 30_000,
    history_limit: 287
  ],
  
  # API client configuration
  api: [
    base_url: "https://pro-api.coinmarketcap.com/v1",
    allowed_ips: [
      "18.155.202.48",
      "18.155.202.11",
      "18.155.202.47",
      "18.155.202.124"
    ],
    api_key: System.get_env("COIN_MARKET_CAP_API_KEY") || "",
    request_timeout: 10_000
  ],
  
  # Transaction configuration
  transaction: [
    min_purchase_amount: 0.01,
    min_sell_amount: 0.00000001,
    buy_max_threshold: 0.01
  ],
  
  # PubSub topic configuration
  pubsub: [
    price_updates_topic: "price_updates",
    wallet_updates_topic: "wallet_updates"
  ]

# Configures the endpoint
config :bitcoin_exchange, BitcoinExchangeWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: BitcoinExchangeWeb.ErrorHTML, json: BitcoinExchangeWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: BitcoinExchange.PubSub,
  live_view: [signing_salt: "s61jUUVq"]


# Configure esbuild (the version is required)
config :esbuild,
  version: "0.17.11",
  bitcoin_exchange: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "3.4.3",
  bitcoin_exchange: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
