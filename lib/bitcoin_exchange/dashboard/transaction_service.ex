defmodule BitcoinExchange.Dashboard.TransactionService do
  @moduledoc """
  Service module for handling Bitcoin transactions.
  
  This module extracts the complex transaction handling logic from the LiveView,
  including buy and sell operations, validation, and error handling.
  """
  
  require Logger
  alias BitcoinExchange.Accounts
  alias BitcoinExchange.Dashboard.UIHelpers
  alias BitcoinExchange.Config.TransactionConfig
  alias BitcoinExchange.Utils.DecimalUtils, as: DU
  alias Decimal, as: D
  
  @doc """
  Handles a transaction (buy or sell) based on the provided parameters.
  
  ## Parameters
  - type: The transaction type (:buy or :sell)
  - amount_str: String representation of the amount
  - assigns: Current LiveView assigns containing price and balance data
  
  ## Returns
  - {:ok, updated_assigns} on success
  - {:error, error_message} on failure
  """
  def handle_transaction(type, amount_str, assigns) do
    operation_name = if type == :buy, do: "Buying Bitcoin with USD", else: "Selling Bitcoin"
    Logger.info("#{operation_name}: #{amount_str}")

    # Normalize input - ensure leading 0 for decimal inputs
    normalized_amount_str = 
      if String.starts_with?(amount_str, ".") do
        "0" <> amount_str
      else
        amount_str
      end
      
    case Float.parse(normalized_amount_str) do
      {amount, _} when amount > 0 ->
        # Determine minimum thresholds based on operation type
        {min_threshold, min_error_message} = 
          if type == :buy do
            {TransactionConfig.min_purchase_amount(), TransactionConfig.min_purchase_message()}
          else
            {TransactionConfig.min_sell_amount(), TransactionConfig.min_sell_message()}
          end
          
        if amount < min_threshold do
          {:error, min_error_message}
        else
          # Round values based on operation type
          {balance_to_check, rounded_amount, decimal_places} = 
            if type == :buy do
              {assigns.cash_balance, amount, 2}
            else
              {assigns.bitcoin_balance, amount, 8}
            end
            
          rounded_balance = Float.round(balance_to_check, decimal_places)
          rounded_amount = Float.round(rounded_amount, decimal_places)

          # Determine if this is a "max" operation based on the transaction type
          is_max_operation = 
            if type == :buy do
              # For buy operations, we consider it "max" if very close to balance
              abs(rounded_amount - rounded_balance) < TransactionConfig.buy_max_threshold()
            else
              # For sell operations, it must match exactly
              rounded_amount == rounded_balance
            end

          Logger.info(
            "Is Max Operation? #{is_max_operation}, amount: #{rounded_amount}, balance: #{rounded_balance}"
          )

          # If this is a max operation, use the exact balance to avoid precision issues
          actual_amount = if is_max_operation, do: rounded_balance, else: rounded_amount

          # Validate balance - skip for max operations since we already know it's valid
          if not is_max_operation and rounded_amount > rounded_balance do
            error_message = 
              if type == :buy do
                "Insufficient funds. Maximum available: $#{UIHelpers.format_currency(rounded_balance)}"
              else
                "Insufficient Bitcoin. You have #{UIHelpers.format_btc(rounded_balance)} BTC available."
              end
              
            {:error, error_message}
          else
            execute_transaction(type, actual_amount, is_max_operation, assigns)
          end
        end
        
      _ ->
        Logger.error("Invalid amount format: #{amount_str}")
        {:error, "Please enter a valid positive amount"}
    end
  end
  
  defp execute_transaction(type, actual_amount, is_max_operation, assigns) do
    try do
      formatted_amount = 
        if type == :buy do
          Logger.info("Calculating BTC amount for USD: #{actual_amount}")
          
          btc_amount = DU.div(actual_amount, assigns.bitcoin_price)
          Logger.info("BTC to purchase: #{btc_amount}")
          
          formatted_btc_amount =
            cond do
              is_struct(btc_amount, Decimal) ->
                Decimal.round(btc_amount, 8) |> Decimal.to_float()
              is_float(btc_amount) ->
                Float.parse(:erlang.float_to_binary(btc_amount, decimals: 8)) |> elem(0)
              true ->
                btc_amount
            end
            
          formatted_btc_amount
        else
          Float.parse(:erlang.float_to_binary(actual_amount, decimals: 8)) |> elem(0)
        end
        
      Logger.info("Formatted amount: #{formatted_amount}")

      btc_price = 
        if is_struct(assigns.bitcoin_price, Decimal) do
          Decimal.to_float(assigns.bitcoin_price)
        else
          assigns.bitcoin_price
        end
        
      result = 
        if type == :buy do
          Accounts.buy_bitcoin(formatted_amount, btc_price)
        else
          Accounts.sell_bitcoin(formatted_amount, btc_price)
        end
        
      case result do
        {:ok, updated_wallet} ->
          operation_msg = if type == :buy, do: "bought", else: "sold"
          Logger.info(
            "Successfully #{operation_msg} #{formatted_amount} BTC. New balances: $#{D.to_float(updated_wallet.cash_balance)}, #{D.to_float(updated_wallet.bitcoin_balance)} BTC"
          )
          
          transactions = Accounts.get_transactions()
          formatted_transactions = format_transactions(transactions)
          
          cash_balance = 
            if type == :buy && is_max_operation do
              0.0
            else
              Float.round(D.to_float(updated_wallet.cash_balance), 2)
            end
            
          bitcoin_balance = 
            if type != :buy && is_max_operation do
              0.0
            else
              D.to_float(updated_wallet.bitcoin_balance)
            end
            
          bitcoin_value = calculate_bitcoin_value(bitcoin_balance, assigns.bitcoin_price)
          total_value = calculate_total_value(cash_balance, bitcoin_balance, assigns.bitcoin_price)
          
          {:ok, %{
            cash_balance: cash_balance,
            bitcoin_balance: bitcoin_balance,
            bitcoin_value: bitcoin_value,
            total_value: total_value,
            transactions: formatted_transactions,
            modal_form: nil,
            form_error: nil
          }}
        
        {:error, :insufficient_funds} when type == :buy ->
          Logger.error("Insufficient funds to buy Bitcoin")
          {:error, TransactionConfig.insufficient_funds_message()}
          
        {:error, :insufficient_bitcoin} when type != :buy ->
          Logger.error("Insufficient Bitcoin to sell")
          {:error, "Insufficient Bitcoin. You have #{UIHelpers.format_btc(assigns.bitcoin_balance)} BTC available."}
          
        {:error, reason} ->
          operation = if type == :buy, do: "buy", else: "sell"
          Logger.error("Failed to #{operation} Bitcoin: #{reason}")
          {:error, "Transaction failed: #{reason}"}
      end
    rescue
      e ->
        stacktrace = Exception.format_stacktrace(__STACKTRACE__)
        operation = if type == :buy, do: "buying", else: "selling"
        Logger.error("Exception when #{operation} Bitcoin: #{inspect(e)}")
        Logger.error("Stacktrace: #{stacktrace}")
        {:error, "Error processing transaction: #{inspect(e)}"}
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

      # Add transaction-specific fields
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