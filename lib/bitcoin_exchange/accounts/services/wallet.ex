defmodule BitcoinExchange.Accounts.Services.Wallet do
  @moduledoc """
  GenServer implementation for the Wallet service.
  
  This service is responsible for all wallet operations including:
  - Managing the user's cash and Bitcoin balances
  - Processing buy/sell transactions
  - Tracking transaction history
  - Broadcasting wallet updates to subscribers
  """
  use GenServer
  require Logger
  alias BitcoinExchange.Accounts.WalletState
  alias BitcoinExchange.Transactions.Transaction
  alias BitcoinExchange.Config.WalletConfig
  alias BitcoinExchange.Config.PubSubConfig
  alias Decimal, as: D

  # ===========================
  # Client API
  # ===========================

  @doc """
  Starts the wallet process.
  
  ## Parameters
  - opts: Options to pass to GenServer.start_link/3, may contain:
    - `:transaction_module` - The module used for creating transactions (defaults to Transaction)
    - `:pubsub_module` - The module used for broadcasting updates (defaults to Phoenix.PubSub)
  """
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Gets the current wallet state.
  """
  def get_wallet do
    GenServer.call(__MODULE__, :get_wallet, WalletConfig.genserver_timeout())
  end

  @doc """
  Gets the transaction history.
  """
  def get_transactions do
    GenServer.call(__MODULE__, :get_transactions, WalletConfig.genserver_timeout())
  end

  @doc """
  Adds funds to the cash balance.

  ## Parameters
  - amount: The amount of cash to add (must be positive)

  ## Returns
  - {:ok, updated_wallet} on success
  - {:error, reason} on failure
  """
  def add_cash(amount) when is_number(amount) and amount > 0 do
    try do
      Logger.info("Adding cash: #{amount}")
      GenServer.call(__MODULE__, {:add_cash, amount}, WalletConfig.genserver_timeout())
    rescue
      e ->
        Logger.error("Error in add_cash: #{inspect(e)}")
        {:error, "Failed to process the transaction. Please try again."}
    end
  end

  @doc """
  Updates the Bitcoin balance.

  ## Parameters
  - amount: The new Bitcoin balance (must be non-negative)

  ## Returns
  - {:ok, updated_wallet} on success
  - {:error, reason} on failure
  """
  def update_bitcoin_balance(amount) when is_number(amount) and amount >= 0 do
    try do
      Logger.info("Updating Bitcoin balance to: #{amount}")
      GenServer.call(__MODULE__, {:update_bitcoin_balance, amount}, WalletConfig.genserver_timeout())
    rescue
      e ->
        Logger.error("Error in update_bitcoin_balance: #{inspect(e)}")
        {:error, "Failed to update Bitcoin balance. Please try again."}
    end
  end

  @doc """
  Buy Bitcoin with cash at the current market price.

  ## Parameters
  - btc_amount: The amount of Bitcoin to buy
  - btc_price: The price per Bitcoin

  ## Returns
  - {:ok, updated_wallet} on success
  - {:error, reason} on failure
  """
  def buy_bitcoin(btc_amount, btc_price)
      when is_number(btc_amount) and btc_amount > 0 and is_number(btc_price) and btc_price > 0 do
    try do
      Logger.info("Buying Bitcoin: #{btc_amount} BTC at $#{btc_price}")
      GenServer.call(__MODULE__, {:buy_bitcoin, btc_amount, btc_price}, WalletConfig.genserver_timeout())
    rescue
      e ->
        Logger.error("Error in buy_bitcoin: #{inspect(e)}")
        {:error, "Failed to process the transaction. Please try again."}
    end
  end

  @doc """
  Sell Bitcoin for cash at the current market price.

  ## Parameters
  - btc_amount: The amount of Bitcoin to sell
  - btc_price: The price per Bitcoin

  ## Returns
  - {:ok, updated_wallet} on success
  - {:error, reason} on failure
  """
  def sell_bitcoin(btc_amount, btc_price)
      when is_number(btc_amount) and btc_amount > 0 and is_number(btc_price) and btc_price > 0 do
    try do
      Logger.info("Selling Bitcoin: #{btc_amount} BTC at $#{btc_price}")
      GenServer.call(__MODULE__, {:sell_bitcoin, btc_amount, btc_price}, WalletConfig.genserver_timeout())
    rescue
      e ->
        Logger.error("Error in sell_bitcoin: #{inspect(e)}")
        {:error, "Failed to process the transaction. Please try again."}
    end
  end

  @doc """
  Calculates the total wallet value based on current Bitcoin price.

  ## Parameters
  - wallet: The wallet state
  - btc_price: The current Bitcoin price in USD

  ## Returns
  - The total wallet value as a Decimal
  """
  def calculate_total_value(wallet, btc_price) when is_number(btc_price) do
    btc_price_decimal = D.new(btc_price)
    btc_value = D.mult(wallet.bitcoin_balance, btc_price_decimal)
    D.add(wallet.cash_balance, btc_value)
  end
  
  # Handle Decimal btc_price
  def calculate_total_value(wallet, btc_price) when is_struct(btc_price, Decimal) do
    btc_value = D.mult(wallet.bitcoin_balance, btc_price)
    D.add(wallet.cash_balance, btc_value)
  end

  # ===========================
  # Server Callbacks
  # ===========================

  @impl true
  def init(opts) do
    Logger.info("Wallet process starting...")

    # Extract dependencies from options with defaults
    transaction_module = Keyword.get(opts, :transaction_module, Transaction)
    pubsub_module = Keyword.get(opts, :pubsub_module, Phoenix.PubSub)

    # Get configuration values
    initial_balance = WalletConfig.initial_balance()
    initial_bitcoin_balance = WalletConfig.initial_bitcoin_balance()

    # Create initial wallet state with default balance
    {:ok, wallet} = WalletState.new(initial_balance, initial_bitcoin_balance)
    
    # Create initial cash deposit transaction
    {:ok, transaction} = transaction_module.new_cash_deposit(initial_balance)
    
    # Initial state with wallet, transactions, and dependencies
    initial_state = %{
      wallet: wallet,
      transactions: [transaction],
      transaction_module: transaction_module,
      pubsub_module: pubsub_module
    }
    
    Logger.info("Wallet initialized with $#{initial_balance} cash and #{initial_bitcoin_balance} BTC")

    {:ok, initial_state}
  end

  @impl true
  def handle_call(:get_wallet, _from, state) do
    {:reply, state.wallet, state}
  end

  @impl true
  def handle_call(:get_transactions, _from, state) do
    {:reply, state.transactions, state}
  end

  @impl true
  def handle_call({:add_cash, amount}, _from, state) do
    transaction_module = state.transaction_module
    
    case add_cash_to_wallet(state.wallet, amount, transaction_module) do
      {:ok, updated_wallet, transaction} ->
        # Update state with new wallet and transaction
        updated_state = %{
          state |
          wallet: updated_wallet,
          transactions: [transaction | state.transactions]
        }
        
        # Broadcast wallet update
        broadcast_wallet_update(updated_wallet, updated_state.transactions, state.pubsub_module)
        
        Logger.info(
          "Added $#{amount} to wallet. New balance: $#{Decimal.to_string(updated_wallet.cash_balance)}"
        )

        {:reply, {:ok, updated_wallet}, updated_state}

      {:error, reason} ->
        Logger.error("Error in handle_call(:add_cash): #{inspect(reason)}")
        {:reply, {:error, reason}, state}
    end
  end

  @impl true
  def handle_call({:update_bitcoin_balance, amount}, _from, state) do
    case update_btc_balance(state.wallet, amount) do
      {:ok, updated_wallet} ->
        # Update state with new wallet
        updated_state = %{state | wallet: updated_wallet}
        
        # Broadcast wallet update using the injected pubsub module
        broadcast_wallet_update(updated_wallet, updated_state.transactions, state.pubsub_module)
        
        Logger.info("Updated Bitcoin balance to #{amount} BTC")
        
        {:reply, {:ok, updated_wallet}, updated_state}
        
      {:error, reason} ->
        Logger.error("Error in handle_call(:update_bitcoin_balance): #{inspect(reason)}")
        {:reply, {:error, reason}, state}
    end
  end

  @impl true
  def handle_call({:buy_bitcoin, btc_amount, btc_price}, _from, state) do
    transaction_module = state.transaction_module
    
    case execute_bitcoin_purchase(state.wallet, btc_amount, btc_price, transaction_module) do
      {:ok, updated_wallet, transaction} ->
        # Update state with new wallet and transaction
        updated_state = %{
          state |
          wallet: updated_wallet,
          transactions: [transaction | state.transactions]
        }
        
        # Broadcast wallet update using the injected pubsub module
        broadcast_wallet_update(updated_wallet, updated_state.transactions, state.pubsub_module)
        
        Logger.info(
          "Bought #{btc_amount} BTC at $#{btc_price}. Cash: $#{Decimal.to_string(updated_wallet.cash_balance)}, BTC: #{Decimal.to_string(updated_wallet.bitcoin_balance)}"
        )
        
        {:reply, {:ok, updated_wallet}, updated_state}
        
      {:error, reason} ->
        if reason == :insufficient_funds do
          Logger.info(
            "Insufficient funds: $#{Decimal.to_string(state.wallet.cash_balance)} needed for $#{btc_amount * btc_price}"
          )
        else
          Logger.error("Error in handle_call(:buy_bitcoin): #{inspect(reason)}")
        end
        
        {:reply, {:error, reason}, state}
    end
  end

  @impl true
  def handle_call({:sell_bitcoin, btc_amount, btc_price}, _from, state) do
    transaction_module = state.transaction_module
    
    case execute_bitcoin_sale(state.wallet, btc_amount, btc_price, transaction_module) do
      {:ok, updated_wallet, transaction} ->
        # Update state with new wallet and transaction
        updated_state = %{
          state |
          wallet: updated_wallet,
          transactions: [transaction | state.transactions]
        }
        
        # Broadcast wallet update using the injected pubsub module
        broadcast_wallet_update(updated_wallet, updated_state.transactions, state.pubsub_module)
        
        Logger.info(
          "Sold #{btc_amount} BTC at $#{btc_price}. Cash: $#{Decimal.to_string(updated_wallet.cash_balance)}, BTC: #{Decimal.to_string(updated_wallet.bitcoin_balance)}"
        )
        
        {:reply, {:ok, updated_wallet}, updated_state}
        
      {:error, reason} ->
        if reason == :insufficient_bitcoin do
          Logger.info(
            "Insufficient Bitcoin: #{Decimal.to_string(state.wallet.bitcoin_balance)} BTC < #{btc_amount} BTC"
          )
        else
          Logger.error("Error in handle_call(:sell_bitcoin): #{inspect(reason)}")
        end
        
        {:reply, {:error, reason}, state}
    end
  end

  # ===========================
  # Private Functions
  # ===========================
  
  defp add_cash_to_wallet(wallet, amount, transaction_module) when is_number(amount) and amount > 0 do
    try do
      decimal_amount = ensure_decimal(amount)
      
      attrs = %{
        cash_balance: D.add(wallet.cash_balance, decimal_amount),
        updated_at: DateTime.utc_now()
      }
      
      changeset = WalletState.changeset(wallet, attrs)
      
      if changeset.valid? do
        updated_wallet = Ecto.Changeset.apply_changes(changeset)
        
        case transaction_module.new_cash_deposit(amount) do
          {:ok, transaction} ->
            {:ok, updated_wallet, transaction}
          {:error, _} = error ->
            error
        end
      else
        {:error, changeset}
      end
    rescue
      e -> {:error, "Failed to add cash: #{inspect(e)}"}
    end
  end

  defp ensure_decimal(nil), do: D.new(0)
  defp ensure_decimal(value) when is_struct(value, D), do: value
  defp ensure_decimal(value) when is_float(value), do: D.from_float(value)
  defp ensure_decimal(value) when is_integer(value), do: D.new(value)
  defp ensure_decimal(value) when is_binary(value), do: D.new(value)
  
  defp update_btc_balance(wallet, amount) when is_number(amount) and amount >= 0 do
    try do
      decimal_amount = ensure_decimal(amount)
      
      attrs = %{
        bitcoin_balance: decimal_amount,
        updated_at: DateTime.utc_now()
      }
      
      changeset = WalletState.changeset(wallet, attrs)
      
      if changeset.valid? do
        {:ok, Ecto.Changeset.apply_changes(changeset)}
      else
        {:error, changeset}
      end
    rescue
      e -> {:error, "Failed to update Bitcoin balance: #{inspect(e)}"}
    end
  end
  
  defp execute_bitcoin_purchase(wallet, btc_amount, btc_price, transaction_module) 
      when is_number(btc_amount) and btc_amount > 0 
      and is_number(btc_price) and btc_price > 0 do
    try do
      decimal_btc_amount = ensure_decimal(btc_amount)
      decimal_price = ensure_decimal(btc_price)
      cash_needed = D.mult(decimal_btc_amount, decimal_price)
      
      rounded_cash_balance = D.round(wallet.cash_balance, 2)
      rounded_cash_needed = D.round(cash_needed, 2)
      is_buy_max = D.compare(D.sub(rounded_cash_balance, rounded_cash_needed), D.new("0.01")) in [:eq, :lt]
      adjusted_cash_needed = if is_buy_max, do: wallet.cash_balance, else: cash_needed
      
      if not is_buy_max and D.lt?(wallet.cash_balance, cash_needed) do
        {:error, :insufficient_funds}
      else
        updated_cash = if is_buy_max, do: D.new(0), else: D.sub(wallet.cash_balance, adjusted_cash_needed)
        updated_btc = D.add(wallet.bitcoin_balance, decimal_btc_amount)
        
        attrs = %{
          cash_balance: updated_cash,
          bitcoin_balance: updated_btc,
          updated_at: DateTime.utc_now()
        }
        
        changeset = WalletState.changeset(wallet, attrs)
        
        if changeset.valid? do
          updated_wallet = Ecto.Changeset.apply_changes(changeset)
          
          cash_amount = D.to_float(adjusted_cash_needed)
          case transaction_module.new_bitcoin_purchase(btc_amount, btc_price, cash_amount) do
            {:ok, transaction} ->
              {:ok, updated_wallet, transaction}
            {:error, _} = error ->
              error
          end
        else
          {:error, changeset}
        end
      end
    rescue
      e -> {:error, "Failed to buy Bitcoin: #{inspect(e)}"}
    end
  end
  
  defp execute_bitcoin_sale(wallet, btc_amount, btc_price, transaction_module)
      when is_number(btc_amount) and btc_amount > 0
      and is_number(btc_price) and btc_price > 0 do
    try do
      decimal_btc_amount = ensure_decimal(btc_amount)
      decimal_price = ensure_decimal(btc_price)
      
      if D.lt?(wallet.bitcoin_balance, decimal_btc_amount) do
        {:error, :insufficient_bitcoin}
      else
        rounded_btc = D.round(wallet.bitcoin_balance, 8)
        rounded_btc_amount = D.round(decimal_btc_amount, 8)
        is_sell_max = D.eq?(rounded_btc, rounded_btc_amount)
        
        cash_to_receive = D.mult(decimal_btc_amount, decimal_price)
        
        updated_cash = D.add(wallet.cash_balance, cash_to_receive)
        updated_btc = if is_sell_max, do: D.new(0), else: D.sub(wallet.bitcoin_balance, decimal_btc_amount)
        
        attrs = %{
          cash_balance: updated_cash,
          bitcoin_balance: updated_btc,
          updated_at: DateTime.utc_now()
        }
        
        changeset = WalletState.changeset(wallet, attrs)
        
        if changeset.valid? do
          updated_wallet = Ecto.Changeset.apply_changes(changeset)
          
          cash_amount = D.to_float(cash_to_receive)
          case transaction_module.new_bitcoin_sale(btc_amount, btc_price, cash_amount) do
            {:ok, transaction} ->
              {:ok, updated_wallet, transaction}
            {:error, _} = error ->
              error
          end
        else
          {:error, changeset}
        end
      end
    rescue
      e -> {:error, "Failed to sell Bitcoin: #{inspect(e)}"}
    end
  end
  
  defp broadcast_wallet_update(wallet, transactions, pubsub_module) do
    pubsub_module.broadcast(
      BitcoinExchange.PubSub,
      PubSubConfig.wallet_updates_topic(),
      {:wallet_updated, wallet, transactions}
    )
  end
end