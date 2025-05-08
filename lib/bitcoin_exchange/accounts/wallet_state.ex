defmodule BitcoinExchange.Accounts.WalletState do
  @moduledoc """
  Schema for the user's wallet state.
  
  This schema represents the user's wallet, including cash and Bitcoin balances.
  It is responsible only for data structure and validations.
  """
  
  use Ecto.Schema
  import Ecto.Changeset
  alias Decimal, as: D
  
  @primary_key false
  embedded_schema do
    field :cash_balance, :decimal
    field :bitcoin_balance, :decimal
    field :updated_at, :utc_datetime
  end
  
  @doc """
  Creates a changeset for the wallet state.

  ## Parameters
  - wallet: The wallet state struct to be updated
  - attrs: A map of attributes to apply to the wallet state

  ## Returns
  - An Ecto.Changeset
  """
  def changeset(wallet, attrs) do
    wallet
    |> cast(attrs, [:cash_balance, :bitcoin_balance, :updated_at])
    |> validate_required([:cash_balance, :bitcoin_balance, :updated_at])
    |> validate_number(:cash_balance, greater_than_or_equal_to: 0)
    |> validate_number(:bitcoin_balance, greater_than_or_equal_to: 0)
  end
  
  @doc """
  Creates a new wallet with initial cash and Bitcoin balances.

  ## Parameters
  - cash_balance: Initial cash balance (defaults to 10,000)
  - bitcoin_balance: Initial Bitcoin balance (defaults to 0)

  ## Returns
  - {:ok, wallet} on success
  - {:error, changeset} on validation failure
  """
  def new(cash_balance \\ 10_000, bitcoin_balance \\ 0) do
    attrs = %{
      cash_balance: D.new(cash_balance),
      bitcoin_balance: D.new(bitcoin_balance),
      updated_at: DateTime.utc_now()
    }
    
    changeset = changeset(%__MODULE__{}, attrs)
    
    if changeset.valid? do
      {:ok, apply_changes(changeset)}
    else
      {:error, changeset}
    end
  end
end