defmodule BitcoinExchange.Market.CoinMarketCapClient do
  @moduledoc """
  Client for the CoinMarketCap API.

  This client handles API requests to CoinMarketCap for retrieving
  cryptocurrency price data.

  The Hobbyist tier ($29/month) allows:
  - Access to current price data
  - Up to 1 month of historical price data
  - Using endpoints like `/cryptocurrency/quotes/latest` for current quotes
  """

  require Logger
  alias BitcoinExchange.Config.ApiConfig
  alias BitcoinExchange.Market.Services.{ApiClientFactory, BaseApiClient}

  @base_url ApiConfig.base_url()

  @doc """
  Get the latest quotes for Bitcoin using its CoinMarketCap ID (recommended).

  Uses the `/cryptocurrency/quotes/latest` endpoint with ID parameter, which is
  more reliable than using symbols according to CoinMarketCap docs.

  ## Parameters
  - id: The cryptocurrency CoinMarketCap ID (e.g., 1 for Bitcoin)
  - convert_to: The currency to convert to (e.g., "USD")

  ## Returns
  - {:ok, %{
      price: float,
      volume_24h: float,
      market_cap: float,
      percent_change_1h: float,
      percent_change_24h: float,
      percent_change_7d: float,
      timestamp: DateTime.t()
    }} on success
  - {:error, reason} on failure
  """
  def get_crypto_quote_by_id(id, convert_to) do
    api_key = ApiConfig.api_key()
    
    if api_key == "" do
      Logger.error("No API key configured for CoinMarketCap. API requests will fail.")
      {:error, "No API key configured for CoinMarketCap"}
    else
      url = "#{@base_url}/cryptocurrency/quotes/latest?id=#{id}&convert=#{convert_to}"
      headers = ApiConfig.common_headers()
      client = ApiClientFactory.get_client()

      Logger.debug("Calling CoinMarketCap API for crypto ID #{id} quote in #{convert_to}")
      BaseApiClient.log_request("GET", url, headers)

      with {:ok, body} <- client.get_with_direct_ip(url, headers),
           {:ok, data} <- BaseApiClient.parse_json(body),
           {:ok, result} <- extract_quote_data(data, id, convert_to) do
        {:ok, result}
      else
        {:error, reason} ->
          Logger.error("CoinMarketCap API request failed: #{inspect(reason)}")
          {:error, "API request failed: #{inspect(reason)}"}
      end
    end
  end

  defp extract_quote_data(data, id, convert_to) do
    try do
      id_str = Integer.to_string(id)
      crypto_data = data["data"][id_str]
      quote_data = crypto_data["quote"][convert_to]

      result = %{
        price: quote_data["price"],
        volume_24h: quote_data["volume_24h"],
        market_cap: quote_data["market_cap"],
        percent_change_1h: quote_data["percent_change_1h"],
        percent_change_24h: quote_data["percent_change_24h"],
        percent_change_7d: quote_data["percent_change_7d"],
        timestamp: DateTime.utc_now()
      }

      {:ok, result}
    rescue
      e ->
        Logger.error("Error extracting data from CoinMarketCap response: #{inspect(e)}")
        Logger.debug("Response data: #{inspect(data)}")
        {:error, "Failed to extract data from API response"}
    end
  end

  @doc """
  Get the latest price for a given cryptocurrency using its CoinMarketCap ID.

  Uses the `/tools/price-conversion` endpoint with ID parameter instead of symbol.

  ## Parameters
  - id: The cryptocurrency CoinMarketCap ID (e.g., "1" for Bitcoin)
  - convert_to: The currency to convert to (e.g., "USD")

  ## Returns
  - {:ok, %{price: float, timestamp: DateTime.t()}} on success
  - {:error, reason} on failure
  """
  def get_latest_price_by_id(id, convert_to) do
    url = "#{@base_url}/tools/price-conversion?id=#{id}&convert=#{convert_to}&amount=1"
    headers = ApiConfig.common_headers()
    client = ApiClientFactory.get_client()

    Logger.debug("Calling CoinMarketCap API for crypto ID #{id} price in #{convert_to}")
    BaseApiClient.log_request("GET", url, headers)

    with {:ok, body} <- client.get_with_direct_ip(url, headers),
         {:ok, data} <- BaseApiClient.parse_json(body),
         {:ok, price} <- extract_price_data(data, convert_to) do
      {:ok, %{price: price, timestamp: DateTime.utc_now()}}
    else
      {:error, reason} ->
        Logger.error("CoinMarketCap API request failed: #{inspect(reason)}")
        {:error, "API request failed: #{inspect(reason)}"}
    end
  end

  defp extract_price_data(data, convert_to) do
    try do
      price = data["data"]["quote"][convert_to]["price"]
      {:ok, price}
    rescue
      e ->
        Logger.error("Error extracting price from CoinMarketCap response: #{inspect(e)}")
        Logger.debug("Response data: #{inspect(data)}")
        {:error, "Failed to extract price from API response"}
    end
  end

  @doc """
  Get historical price data for a specific point in time.

  Uses the `/tools/price-conversion` endpoint with the time parameter,
  which allows fetching historical conversions on the Hobbyist plan.

  ## Parameters
  - symbol: The cryptocurrency symbol (e.g., "BTC")
  - convert_to: The currency to convert to (e.g., "USD")
  - timestamp: The point in time to get the price for (DateTime)

  ## Returns
  - {:ok, %{price: float, timestamp: DateTime.t()}} on success
  - {:error, reason} on failure
  """
  def get_historical_price(symbol, convert_to, timestamp) do
    iso_time = DateTime.to_iso8601(timestamp)
    url = "#{@base_url}/tools/price-conversion?symbol=#{symbol}&convert=#{convert_to}&amount=1&time=#{iso_time}"
    headers = ApiConfig.common_headers()
    client = ApiClientFactory.get_client()

    Logger.debug("Calling CoinMarketCap API for historical #{symbol} price in #{convert_to} at #{iso_time}")
    BaseApiClient.log_request("GET", url, headers)

    with {:ok, body} <- client.get_with_direct_ip(url, headers),
         {:ok, data} <- BaseApiClient.parse_json(body),
         {:ok, price} <- extract_price_data(data, convert_to) do
      {:ok, %{price: price, timestamp: timestamp}}
    else
      {:error, reason} ->
        Logger.error("CoinMarketCap API request failed: #{inspect(reason)}")
        {:error, "API request failed: #{inspect(reason)}"}
    end
  end
end