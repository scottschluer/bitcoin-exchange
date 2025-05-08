defmodule BitcoinExchange.Dashboard.DashboardService do
  @moduledoc """
  Service module for dashboard-related business logic.

  This module serves as a coordinator for operations related to the dashboard,
  including initializing dashboard data, processing price updates, and
  handling wallet updates. It provides a clean interface for the LiveView
  to interact with business logic without managing those details directly.
  """

  require Logger
  alias Phoenix.PubSub
  alias BitcoinExchange.Market
  alias BitcoinExchange.Accounts
  alias BitcoinExchange.Utils.DecimalUtils, as: DU
  alias BitcoinExchange.Config.PubSubConfig
  alias Decimal, as: D
  
  @doc """
  Initialize dashboard data for the LiveView.
  
  Fetches current price data, wallet data, and transactions.
  Returns a map with all the data needed to initialize the dashboard.
  """
  def initialize_dashboard do
    price_topic = PubSubConfig.price_updates_topic()
    Logger.info("DashboardService subscribing to #{price_topic}")
    PubSub.subscribe(BitcoinExchange.PubSub, price_topic)

    wallet_topic = PubSubConfig.wallet_updates_topic()
    Logger.info("DashboardService subscribing to #{wallet_topic}")
    PubSub.subscribe(BitcoinExchange.PubSub, wallet_topic)

    price_data = Market.get_current_data()
    wallet = Accounts.get_wallet()
    transactions = Accounts.get_transactions()

    cash_balance = D.to_float(wallet.cash_balance)
    bitcoin_balance = D.to_float(wallet.bitcoin_balance)
    bitcoin_value = calculate_bitcoin_value(bitcoin_balance, price_data.bitcoin_price)
    total_value = calculate_total_value(cash_balance, bitcoin_balance, price_data.bitcoin_price)

    formatted_transactions = format_transactions(transactions)

    %{
      bitcoin_price: price_data.bitcoin_price,
      previous_price: price_data.previous_price,
      price_change_1h: Map.get(price_data, :price_change_1h, Decimal.new(0)),
      price_change_24h: price_data.price_change_24h,
      price_change_7d: price_data.price_change_7d,
      volume_24h: price_data.volume_24h,
      market_cap: price_data.market_cap,
      cash_balance: cash_balance,
      bitcoin_balance: bitcoin_balance,
      bitcoin_value: bitcoin_value,
      total_value: total_value,
      transactions: formatted_transactions,
      modal_form: nil,
      form_error: nil
    }
  end

  @doc """
  Process a price update event from PubSub.
  
  Calculates new bitcoin value and total portfolio value based on
  the updated price data.
  """
  def process_price_update(assigns, price_data) do
    Logger.debug("DashboardService processing price update: #{price_data.bitcoin_price}")

    bitcoin_value =
      calculate_bitcoin_value(assigns.bitcoin_balance, price_data.bitcoin_price)

    total_value =
      calculate_total_value(
        assigns.cash_balance,
        assigns.bitcoin_balance,
        price_data.bitcoin_price
      )

    %{
      bitcoin_price: price_data.bitcoin_price,
      previous_price: price_data.previous_price,
      price_change_1h: Map.get(price_data, :price_change_1h, Decimal.new(0)),
      price_change_24h: price_data.price_change_24h,
      price_change_7d: price_data.price_change_7d,
      volume_24h: price_data.volume_24h,
      market_cap: price_data.market_cap,
      bitcoin_value: bitcoin_value,
      total_value: total_value
    }
  end

  @doc """
  Process a wallet update event from PubSub.
  
  Updates wallet-related data including balances and transactions.
  Handles both legacy format and new format with transactions.
  """
  def process_wallet_update(assigns, wallet, transactions \\ nil) do
    Logger.debug("DashboardService processing wallet update")

    cash_balance = D.to_float(wallet.cash_balance)
    bitcoin_balance = D.to_float(wallet.bitcoin_balance)
    bitcoin_value = calculate_bitcoin_value(bitcoin_balance, assigns.bitcoin_price)

    total_value =
      calculate_total_value(cash_balance, bitcoin_balance, assigns.bitcoin_price)

    transactions_to_format = transactions || Accounts.get_transactions()
    formatted_transactions = format_transactions(transactions_to_format)

    %{
      cash_balance: cash_balance,
      bitcoin_balance: bitcoin_balance,
      bitcoin_value: bitcoin_value,
      total_value: total_value,
      transactions: formatted_transactions,
      form_error: nil
    }
  end

  @doc """
  Adds funds to the user's wallet.
  
  ## Parameters
  - amount_str: String representation of the amount to add
  
  ## Returns
  - {:ok, updated_assigns} on success
  - {:error, reason} on failure
  """
  def add_funds(assigns, amount_str) do
    Logger.info("Adding funds form submitted with amount: #{amount_str}")

    case Float.parse(amount_str) do
      {amount, _} when amount > 0 ->
        Logger.info("Parsed amount: #{amount}, calling Accounts.add_cash")

        try do
          # Call the wallet service
          case Accounts.add_cash(amount) do
            {:ok, updated_wallet} ->
              Logger.info("Funds added successfully, wallet updated")

              cash_balance = D.to_float(updated_wallet.cash_balance)
              bitcoin_balance = D.to_float(updated_wallet.bitcoin_balance)

              bitcoin_value =
                calculate_bitcoin_value(bitcoin_balance, assigns.bitcoin_price)

              total_value =
                calculate_total_value(cash_balance, bitcoin_balance, assigns.bitcoin_price)

              transactions = Accounts.get_transactions()
              formatted_transactions = format_transactions(transactions)

              Logger.info("Updating UI with new cash balance: $#{cash_balance}")
              {:ok,
                %{
                  cash_balance: cash_balance,
                  bitcoin_balance: bitcoin_balance,
                  bitcoin_value: bitcoin_value,
                  total_value: total_value,
                  transactions: formatted_transactions,
                  modal_form: nil,
                  form_error: nil
                }
              }

            {:error, reason} ->
              Logger.error("Error returned from Accounts.add_cash: #{reason}")
              {:error, "Transaction failed: #{reason}"}

            other ->
              Logger.error("Unexpected response from Accounts.add_cash: #{inspect(other)}")
              {:error, "Unexpected response from server"}
          end
        rescue
          e ->
            stacktrace = Exception.format_stacktrace(__STACKTRACE__)
            Logger.error("Exception in add_funds: #{inspect(e)}")
            Logger.error("Stacktrace: #{stacktrace}")
            {:error, "Server error: #{inspect(e)}"}
        catch
          kind, reason ->
            Logger.error("Caught #{kind} in add_funds: #{inspect(reason)}")
            {:error, "Operation timed out. Please try again."}
        end

      _ ->
        Logger.error("Invalid amount format: #{amount_str}")
        {:error, "Please enter a valid positive amount"}
    end
  end

  defp calculate_bitcoin_value(bitcoin_balance, bitcoin_price) do
    DU.mult(bitcoin_balance, bitcoin_price)
  end

  defp calculate_total_value(cash_balance, bitcoin_balance, bitcoin_price) do
    bitcoin_value = calculate_bitcoin_value(bitcoin_balance, bitcoin_price)
    DU.add(cash_balance, bitcoin_value)
  end
  defp format_transactions(transactions) do
    Enum.map(transactions, fn transaction ->
      type =
        case transaction.type do
          :cash_deposit -> "add_funds"
          :buy_bitcoin -> "buy"
          :sell_bitcoin -> "sell"
        end

      date = DateTime.to_date(transaction.timestamp)
      time = transaction.timestamp

      transaction_id =
        Map.get(
          transaction,
          :transaction_id,
          "LEGACY-#{:crypto.strong_rand_bytes(8) |> Base.encode16()}"
        )

      base_map = %{
        id: transaction_id,
        type: type,
        date: date,
        timestamp: time
      }

      case type do
        "add_funds" ->
          Map.put(base_map, :amount, D.to_float(transaction.amount))

        _ ->
          base_map
          |> Map.put(:amount, D.to_float(transaction.btc_amount))
          |> Map.put(:price, D.to_float(transaction.btc_price))
      end
    end)
  end
end