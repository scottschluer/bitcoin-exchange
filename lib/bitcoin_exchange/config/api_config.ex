defmodule BitcoinExchange.Config.ApiConfig do
  @moduledoc """
  Configuration values for API clients.
  
  This consolidated module handles all API-related configuration, including
  environment-specific settings, API credentials, and client implementations.
  """

  @doc """
  Returns the configured API client implementation to use.
  Currently defaults to the Curl implementation.
  
  ## Returns
  - Module name of the API client implementation
  """
  def client_implementation do
    Application.get_env(
      :bitcoin_exchange,
      :api_client_implementation,
      BitcoinExchange.Market.Services.CurlApiClient
    )
  end

  @doc """
  Base URL for the CoinMarketCap API.
  
  ## Returns
  - String containing the base URL
  """
  def base_url, do: Application.get_env(:bitcoin_exchange, :api)[:base_url] || "https://pro-api.coinmarketcap.com/v1"

  @doc """
  List of allowed IP addresses for CoinMarketCap API.
  Used for direct IP access in case of DNS issues.
  
  ## Returns
  - List of IP addresses as strings
  """
  def allowed_ips do
    Application.get_env(:bitcoin_exchange, :api)[:allowed_ips] || [
      "18.155.202.48",
      "18.155.202.11",
      "18.155.202.47",
      "18.155.202.124"
    ]
  end

  @doc """
  API key for the CoinMarketCap API.
  
  ## Returns
  - String containing the API key
  """
  def api_key do
    # Try to get API key from environment variable first
    System.get_env("COINMARKETCAP_API_KEY") || 
    System.get_env("COIN_MARKET_CAP_API_KEY") || 
    # Fall back to the config value
    Application.get_env(:bitcoin_exchange, :api)[:api_key] || ""
  end

  @doc """
  HTTP request timeout in milliseconds.
  
  ## Returns
  - Integer timeout value in milliseconds
  """
  def request_timeout, do: Application.get_env(:bitcoin_exchange, :api)[:request_timeout] || 10_000

  @doc """
  Returns common headers for CoinMarketCap API requests.
  
  ## Returns
  - List of {header_name, header_value} tuples
  """
  def common_headers do
    key = api_key()
    [
      {"X-CMC_PRO_API_KEY", key},
      {"Host", "pro-api.coinmarketcap.com"},
      {"Accept", "application/json"}
    ]
  end
end