defmodule BitcoinExchange.Market.Price do
  @moduledoc """
  Schema for Bitcoin price data.
  
  This schema defines the structure for price data retrieved from external APIs
  and provides validation through changesets.
  """
  
  use Ecto.Schema
  import Ecto.Changeset
  
  @primary_key false
  embedded_schema do
    field :value, :decimal
    field :currency, :string
    field :timestamp, :utc_datetime
    field :change_24h, :decimal
    field :change_7d, :decimal
    field :volume_24h, :decimal
    field :market_cap, :decimal
  end
  
  @doc """
  Creates a changeset for price data.
  
  ## Parameters
  - price: The price struct to be updated
  - attrs: A map of attributes to apply to the price
  
  ## Returns
  - An Ecto.Changeset
  """
  def changeset(price, attrs) do
    price
    |> cast(attrs, [:value, :currency, :timestamp, :change_24h, :change_7d, :volume_24h, :market_cap])
    |> validate_required([:value, :currency, :timestamp])
    |> validate_number(:value, greater_than: 0)
    |> validate_inclusion(:currency, ["USD", "EUR", "GBP", "JPY", "CNY"])
  end
  
  @doc """
  Creates a changeset for basic price data without all the market metrics.
  
  ## Parameters
  - price: The price struct to be updated
  - attrs: A map of attributes to apply to the price, containing at least value, currency, and timestamp
  
  ## Returns
  - An Ecto.Changeset
  """
  def basic_changeset(price, attrs) do
    price
    |> cast(attrs, [:value, :currency, :timestamp])
    |> validate_required([:value, :currency, :timestamp])
    |> validate_number(:value, greater_than: 0)
    |> validate_inclusion(:currency, ["USD", "EUR", "GBP", "JPY", "CNY"])
  end
  
  @doc """
  Converts a price map from the API to a valid schema.
  
  ## Parameters
  - api_data: Map containing price data from the API
  
  ## Returns
  - {:ok, price} on success
  - {:error, changeset} on validation failure
  """
  def from_api_data(%{price: price, timestamp: timestamp} = api_data) do
    attrs = %{
      value: price,
      currency: api_data[:currency] || "USD",
      timestamp: timestamp,
      change_24h: api_data[:percent_change_24h],
      change_7d: api_data[:percent_change_7d],
      volume_24h: api_data[:volume_24h],
      market_cap: api_data[:market_cap]
    }
    
    changeset = changeset(%__MODULE__{}, attrs)
    
    if changeset.valid? do
      {:ok, apply_changes(changeset)}
    else
      {:error, changeset}
    end
  end
  
  @doc """
  Creates a basic price from value and optional currency.
  
  ## Parameters
  - value: The price value as a number
  - currency: The currency code (optional, defaults to "USD")
  
  ## Returns
  - {:ok, price} on success
  - {:error, changeset} on validation failure
  """
  def new(value, currency \\ "USD") when is_number(value) and value > 0 do
    attrs = %{
      value: value,
      currency: currency,
      timestamp: DateTime.utc_now()
    }
    
    changeset = basic_changeset(%__MODULE__{}, attrs)
    
    if changeset.valid? do
      {:ok, apply_changes(changeset)}
    else
      {:error, changeset}
    end
  end
end