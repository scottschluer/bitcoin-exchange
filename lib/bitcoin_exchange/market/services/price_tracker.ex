defmodule BitcoinExchange.Market.Services.PriceTracker do
  @moduledoc """
  GenServer implementation for the PriceTracker service.

  This service is responsible for fetching and tracking Bitcoin price data
  from external APIs, and broadcasting updates to subscribers. It handles:
  - Periodic price updates with exponential backoff on failures
  - API data fetching and error handling
  - Broadcasting price updates via PubSub
  """

  use GenServer
  require Logger
  alias BitcoinExchange.Market.CoinMarketCapClient
  alias BitcoinExchange.Market.PriceDataState
  alias BitcoinExchange.Utils.LogUtils, as: Log
  alias BitcoinExchange.Utils.PubSubUtils, as: PS
  alias BitcoinExchange.Utils.ChangesetUtils, as: CU
  alias BitcoinExchange.Config.PriceTrackerConfig
  alias BitcoinExchange.Config.PubSubConfig
  alias BitcoinExchange.Config.ApiConfig

  # ===========================
  # Client API
  # ===========================

  @doc """
  Starts the PriceTracker GenServer process.

  ## Parameters
  - opts: Options to pass to GenServer.start_link/3, may contain:
    - `:price_client` - The module used for price fetching (defaults to CoinMarketCapClient)

  ## Returns
  - {:ok, pid} on success
  - {:error, reason} on failure
  """
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Gets the current price data.

  ## Returns
  - Current PriceDataState struct with cleaned history
  """
  def get_current_data do
    try do
      data = GenServer.call(__MODULE__, :get_current_data, PriceTrackerConfig.genserver_timeout())
      PriceDataState.ensure_history_has_maps(data)
    rescue
      e ->
        Log.log_error("get_current_data", e)
        PriceDataState.new_empty()
    end
  end

  # ===========================
  # Server Callbacks
  # ===========================

  @impl true
  def init(opts) do
    Log.log_genserver_start(__MODULE__)

    price_client = Keyword.get(opts, :price_client, CoinMarketCapClient)
    price_data = PriceDataState.new_empty()
    
    initial_state = %{
      price_data: price_data,
      price_client: price_client
    }

    initial_delay = PriceTrackerConfig.initial_update_delay()
    Log.log_scheduler("Initial price update", initial_delay)
    Process.send_after(self(), :update_price, initial_delay)

    {:ok, initial_state}
  end

  @impl true
  def handle_call(:get_current_data, _from, state) do
    price_data = state.price_data
    clean_price_data = PriceDataState.ensure_history_has_maps(price_data)
    updated_state = %{state | price_data: clean_price_data}
    
    {:reply, clean_price_data, updated_state}
  end

  @impl true
  def handle_info(:update_price, state) do
    Logger.debug("PriceTracker attempting to update price")

    price_data = state.price_data
    price_client = state.price_client

    clean_price_data = PriceDataState.ensure_history_has_maps(price_data)
    updated_price_data = fetch_price_data(clean_price_data, price_client)
    final_price_data = PriceDataState.ensure_history_has_maps(updated_price_data)

    Log.log_price_change(price_data.bitcoin_price, final_price_data.bitcoin_price)
    broadcast_price_update(final_price_data)
    schedule_price_update(final_price_data.consecutive_failures)
    
    final_state = %{state | price_data: final_price_data}

    {:noreply, final_state}
  end

  # ===========================
  # Private Functions
  # ===========================

  defp fetch_price_data(price_data, price_client) do
    api_key = ApiConfig.api_key()

    if api_key == "" do
      Logger.error("No API key configured for CoinMarketCap. Unable to fetch price data.")
      PriceDataState.increment_failures(price_data)
    else
      Logger.debug("Attempting to fetch price data from CoinMarketCap")

      bitcoin_id = PriceTrackerConfig.bitcoin_id()
      result = price_client.get_crypto_quote_by_id(bitcoin_id, "USD")
      Logger.debug("API result: #{inspect(result, pretty: true)}")

      case result do
        {:ok, api_data} ->
          handle_successful_api_response(price_data, api_data)

        {:error, reason} ->
          handle_api_error(price_data, reason)
      end
    end
  end

  defp handle_successful_api_response(price_data, api_data) do
    Logger.debug("Successfully parsed API data: #{inspect(api_data, pretty: true)}")
    Logger.info("Successfully fetched price data from CoinMarketCap")

    case update_state_with_api_data(price_data, api_data) do
      {:ok, updated_price_data} ->
        updated_price_data

      {:error, changeset} ->
        Log.log_error("Error validating API data", changeset)
        PriceDataState.increment_failures(price_data)
    end
  end

  defp handle_api_error(price_data, reason) do
    Log.log_error("Failed to fetch price data from CoinMarketCap", reason)

    if has_recent_successful_data?(price_data) do
      Logger.info("Using cached data from last successful API call")
      PriceDataState.increment_failures(price_data)
    else
      Logger.error("No recent price data available. Using last known state.")
      PriceDataState.increment_failures(price_data)
    end
  end

  defp has_recent_successful_data?(price_data) do
    price_data.last_api_success &&
      DateTime.diff(DateTime.utc_now(), price_data.last_api_success) <
        PriceTrackerConfig.cache_valid_seconds()
  end

  defp update_state_with_api_data(price_data, api_data) do
    attrs = %{
      bitcoin_price: api_data.price,
      previous_price: price_data.bitcoin_price,
      price_change_1h: Map.get(api_data, :percent_change_1h, 0),
      price_change_24h: api_data.percent_change_24h,
      price_change_7d: api_data.percent_change_7d,
      volume_24h: api_data.volume_24h,
      market_cap: api_data.market_cap,
      updated_at: api_data.timestamp,
      last_api_success: DateTime.utc_now(),
      consecutive_failures: 0
    }

    new_point = %{
      price: api_data.price,
      timestamp: api_data.timestamp
    }

    history_limit = PriceTrackerConfig.history_limit()
    existing_history = Enum.take(price_data.history || [], history_limit)
    updated_history = [new_point | existing_history]

    attrs = Map.put(attrs, :history, updated_history)

    changeset = PriceDataState.changeset(price_data, attrs)
    CU.apply_if_valid(changeset)
  end

  defp broadcast_price_update(price_data) do
    PS.broadcast(PubSubConfig.price_updates_topic(), {:price_updated, price_data})
  end

  defp schedule_price_update(consecutive_failures) do
    update_interval = PriceTrackerConfig.update_interval()
    max_backoff = PriceTrackerConfig.max_backoff_interval()
    interval = min(update_interval * :math.pow(2, consecutive_failures), max_backoff) |> round()

    Log.log_scheduler("Price update", interval, %{failures: consecutive_failures})

    Process.send_after(self(), :update_price, interval)
  end
end
