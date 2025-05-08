defmodule BitcoinExchange.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    # Load .env file if it exists
    env_path = Path.join(File.cwd!(), ".env")

    if File.exists?(env_path) do
      IO.puts("Loading environment variables from #{env_path}")
      DotenvParser.load_file(env_path)
    else
      IO.puts("No .env file found at #{env_path}")
    end

    children = [
      BitcoinExchangeWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:bitcoin_exchange, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: BitcoinExchange.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: BitcoinExchange.Finch},
      # Start our PriceTracker GenServer with dependencies
      {BitcoinExchange.Market.Services.PriceTracker, [price_client: BitcoinExchange.Market.CoinMarketCapClient]},
      # Start our Wallet GenServer with dependencies
      {BitcoinExchange.Accounts.Services.Wallet, [
        transaction_module: BitcoinExchange.Transactions.Transaction,
        pubsub_module: Phoenix.PubSub
      ]},
      # Start to serve requests, typically the last entry
      BitcoinExchangeWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: BitcoinExchange.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    BitcoinExchangeWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
