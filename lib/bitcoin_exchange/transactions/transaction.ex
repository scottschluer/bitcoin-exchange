defmodule BitcoinExchange.Transactions.Transaction do
  @moduledoc """
  Schema for a wallet transaction.
  
  This schema represents a single transaction in the wallet, such as
  a cash deposit, Bitcoin purchase, or Bitcoin sale.
  """
  
  use Ecto.Schema
  import Ecto.Changeset
  alias BitcoinExchange.Transactions.TransactionID
  alias Decimal, as: D
  
  @primary_key false
  embedded_schema do
    field :type, Ecto.Enum, values: [:cash_deposit, :buy_bitcoin, :sell_bitcoin]
    field :transaction_id, :string
    field :amount, :decimal
    field :btc_amount, :decimal
    field :btc_price, :decimal
    field :timestamp, :utc_datetime
  end
  
  @doc """
  Creates a changeset for a transaction.
  
  ## Parameters
  - transaction: The transaction struct to be updated
  - attrs: A map of attributes to apply to the transaction
  
  ## Returns
  - An Ecto.Changeset
  """
  def changeset(transaction, attrs) do
    transaction
    |> cast(attrs, [:type, :transaction_id, :amount, :btc_amount, :btc_price, :timestamp])
    |> validate_required([:type, :transaction_id, :amount, :timestamp])
    |> validate_transaction_id()
    |> validate_number(:amount, greater_than: 0)
    |> validate_bitcoin_transaction()
  end
  
  # Validates that the transaction_id is properly formatted
  defp validate_transaction_id(changeset) do
    case get_change(changeset, :transaction_id) do
      nil -> changeset
      transaction_id ->
        if TransactionID.valid?(transaction_id) do
          changeset
        else
          add_error(changeset, :transaction_id, "is not a valid transaction ID")
        end
    end
  end
  
  # Validates that Bitcoin-related fields are present and valid for Bitcoin transactions
  defp validate_bitcoin_transaction(changeset) do
    type = get_field(changeset, :type)
    
    case type do
      :cash_deposit -> 
        # For cash deposits, btc_amount and btc_price should be nil
        changeset
        |> validate_nil_field(:btc_amount)
        |> validate_nil_field(:btc_price)
        
      transaction_type when transaction_type in [:buy_bitcoin, :sell_bitcoin] ->
        # For Bitcoin transactions, btc_amount and btc_price are required and must be positive
        changeset
        |> validate_required([:btc_amount, :btc_price])
        |> validate_number(:btc_amount, greater_than: 0)
        |> validate_number(:btc_price, greater_than: 0)
        
      _ ->
        changeset
    end
  end
  
  # Validates that a field is nil
  defp validate_nil_field(changeset, field) do
    case get_field(changeset, field) do
      nil -> changeset
      _ -> add_error(changeset, field, "must be nil for this transaction type")
    end
  end
  
  @doc """
  Creates a new cash deposit transaction.
  
  ## Parameters
  - amount: The amount of cash deposited
  
  ## Returns
  - {:ok, transaction} on success
  - {:error, changeset} on validation failure
  """
  def new_cash_deposit(amount) when is_number(amount) and amount > 0 do
    decimal_amount = D.new("#{amount}")
    transaction_id = TransactionID.generate("add_funds")
    
    attrs = %{
      type: :cash_deposit,
      transaction_id: transaction_id,
      amount: decimal_amount,
      btc_amount: nil,
      btc_price: nil,
      timestamp: DateTime.utc_now()
    }
    
    changeset = changeset(%__MODULE__{}, attrs)
    
    if changeset.valid? do
      {:ok, apply_changes(changeset)}
    else
      {:error, changeset}
    end
  end
  
  @doc """
  Creates a new Bitcoin purchase transaction.
  
  ## Parameters
  - btc_amount: The amount of Bitcoin purchased
  - btc_price: The price per Bitcoin
  - cash_amount: The amount of cash spent (optional, calculated if not provided)
  
  ## Returns
  - {:ok, transaction} on success
  - {:error, changeset} on validation failure
  """
  def new_bitcoin_purchase(btc_amount, btc_price, cash_amount \\ nil)
      when is_number(btc_amount) and btc_amount > 0
      and is_number(btc_price) and btc_price > 0 do
    decimal_btc_amount = D.new("#{btc_amount}")
    decimal_price = D.new("#{btc_price}")
    
    # Calculate cash amount if not provided
    decimal_cash_amount = case cash_amount do
      nil -> D.mult(decimal_btc_amount, decimal_price)
      amount when is_number(amount) and amount > 0 -> D.new("#{amount}")
    end
    
    transaction_id = TransactionID.generate("buy")
    
    attrs = %{
      type: :buy_bitcoin,
      transaction_id: transaction_id,
      amount: decimal_cash_amount,
      btc_amount: decimal_btc_amount,
      btc_price: decimal_price,
      timestamp: DateTime.utc_now()
    }
    
    changeset = changeset(%__MODULE__{}, attrs)
    
    if changeset.valid? do
      {:ok, apply_changes(changeset)}
    else
      {:error, changeset}
    end
  end
  
  @doc """
  Creates a new Bitcoin sale transaction.
  
  ## Parameters
  - btc_amount: The amount of Bitcoin sold
  - btc_price: The price per Bitcoin
  - cash_amount: The amount of cash received (optional, calculated if not provided)
  
  ## Returns
  - {:ok, transaction} on success
  - {:error, changeset} on validation failure
  """
  def new_bitcoin_sale(btc_amount, btc_price, cash_amount \\ nil)
      when is_number(btc_amount) and btc_amount > 0
      and is_number(btc_price) and btc_price > 0 do
    decimal_btc_amount = D.new("#{btc_amount}")
    decimal_price = D.new("#{btc_price}")
    
    # Calculate cash amount if not provided
    decimal_cash_amount = case cash_amount do
      nil -> D.mult(decimal_btc_amount, decimal_price)
      amount when is_number(amount) and amount > 0 -> D.new("#{amount}")
    end
    
    transaction_id = TransactionID.generate("sell")
    
    attrs = %{
      type: :sell_bitcoin,
      transaction_id: transaction_id,
      amount: decimal_cash_amount,
      btc_amount: decimal_btc_amount,
      btc_price: decimal_price,
      timestamp: DateTime.utc_now()
    }
    
    changeset = changeset(%__MODULE__{}, attrs)
    
    if changeset.valid? do
      {:ok, apply_changes(changeset)}
    else
      {:error, changeset}
    end
  end
end