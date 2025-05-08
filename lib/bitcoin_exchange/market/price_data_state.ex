defmodule BitcoinExchange.Market.PriceDataState do
  @moduledoc """
  Schema for the Bitcoin price data state.

  This schema represents the complete state of Bitcoin price data
  including current price, previous price, price changes, volume, market cap,
  and history. It is responsible only for data structure and validations.
  """

  use Ecto.Schema
  import Ecto.Changeset
  alias Decimal, as: D

  @primary_key false
  embedded_schema do
    field(:bitcoin_price, :decimal)
    field(:previous_price, :decimal)
    field(:price_change_1h, :decimal)
    field(:price_change_24h, :decimal)
    field(:price_change_7d, :decimal)
    field(:volume_24h, :decimal)
    field(:market_cap, :decimal)
    field(:updated_at, :utc_datetime)
    field(:last_api_success, :utc_datetime)
    field(:consecutive_failures, :integer, default: 0)
    
    # Store history as a simple list of maps
    field(:history, {:array, :map}, default: [])
  end

  @doc """
  Creates a changeset for the price data state.

  ## Parameters
  - state: The price data state struct to be updated
  - attrs: A map of attributes to apply to the state

  ## Returns
  - An Ecto.Changeset
  """
  def changeset(state, attrs) do
    state
    |> cast(attrs, [
      :bitcoin_price,
      :previous_price,
      :price_change_1h,
      :price_change_24h,
      :price_change_7d,
      :volume_24h,
      :market_cap,
      :updated_at,
      :last_api_success,
      :consecutive_failures,
      :history
    ])
    |> validate_required([:bitcoin_price, :updated_at])
    |> validate_number(:bitcoin_price, greater_than: 0)
    |> validate_number(:consecutive_failures, greater_than_or_equal_to: 0)
  end

  @doc """
  Creates a new empty price data state with default values.

  ## Returns
  - A new PriceDataState struct with default values
  """
  def new_empty do
    %__MODULE__{
      bitcoin_price: D.new(0),
      previous_price: D.new(0),
      price_change_1h: D.new(0),
      price_change_24h: D.new(0),
      price_change_7d: D.new(0),
      volume_24h: D.new(0),
      market_cap: D.new(0),
      updated_at: DateTime.utc_now(),
      history: [],
      consecutive_failures: 0
    }
  end
  
  @doc """
  Increases the consecutive failures count in the price data state.

  ## Parameters
  - state: The current price data state

  ## Returns
  - Updated price data state with incremented failures count
  """
  def increment_failures(state) do
    attrs = %{
      consecutive_failures: state.consecutive_failures + 1
    }

    changeset = changeset(state, attrs)
    apply_changes(changeset)
  end
  
  @doc """
  Ensures that all history items are simple maps with required fields only.
  
  ## Parameters
  - state: The price data state to clean
  
  ## Returns
  - Updated price data state with cleaned history
  """
  def ensure_history_has_maps(state) do
    # Guard against nil or empty history
    history = state.history || []
    
    # Create a clean history array with only the essential fields
    clean_history = 
      Enum.map(history, fn item ->
        cond do
          # If nil, skip it
          is_nil(item) -> nil
          
          # If it's a struct with the right fields
          is_map(item) && is_struct(item) && Map.has_key?(item, :price) && Map.has_key?(item, :timestamp) ->
            %{price: item.price, timestamp: item.timestamp}
            
          # If it's a map with atom keys
          is_map(item) && Map.has_key?(item, :price) && Map.has_key?(item, :timestamp) ->
            %{price: item.price, timestamp: item.timestamp}
            
          # If it's a map with string keys
          is_map(item) && Map.has_key?(item, "price") && Map.has_key?(item, "timestamp") ->
            %{price: item["price"], timestamp: item["timestamp"]}
            
          # If it doesn't have the required fields, skip it
          true -> nil
        end
      end)
      |> Enum.filter(&(&1 != nil))
    
    # Return state with clean history
    %{state | history: clean_history}
  end
end
