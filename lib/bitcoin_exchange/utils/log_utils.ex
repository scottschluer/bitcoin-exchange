defmodule BitcoinExchange.Utils.LogUtils do
  @moduledoc """
  Standardized logging utilities for the application.
  
  This module provides helper functions for consistent log formatting
  and domain-specific logging throughout the application.
  """
  
  require Logger
  alias Decimal, as: D
  
  @price_prefix "[PRICE]"
  @wallet_prefix "[WALLET]"
  @transaction_prefix "[TRANSACTION]"
  @api_prefix "[API]"
  @error_prefix "[ERROR]"
  
  @doc """
  Log API request details for debugging.
  
  ## Parameters
  - method: HTTP method
  - url: The URL being requested
  - headers: Request headers (will be sanitized)
  - body: Request body (optional)
  """
  def log_api_request(method, url, headers, body \\ nil) do
    sanitized_headers = sanitize_headers(headers)
    
    log_message = [
      @api_prefix,
      " Request: #{method} #{url}",
      "\nHeaders: #{inspect(sanitized_headers)}",
      if(body, do: "\nBody: #{inspect(body)}", else: "")
    ]
    
    Logger.debug(Enum.join(log_message, ""))
  end
  
  @doc """
  Log API response details for debugging.
  
  ## Parameters
  - status: HTTP status code
  - url: The URL that was requested
  - headers: Response headers
  - body: Response body (truncated if too large)
  """
  def log_api_response(status, url, headers, body) do
    truncated_body = 
      if is_binary(body) && byte_size(body) > 1000 do
        binary_part(body, 0, 1000) <> "... (truncated)"
      else
        body
      end
    
    log_message = [
      @api_prefix,
      " Response: #{status} from #{url}",
      "\nHeaders: #{inspect(headers)}",
      "\nBody: #{inspect(truncated_body)}"
    ]
    
    if status >= 400 do
      Logger.warning(Enum.join(log_message, ""))
    else
      Logger.debug(Enum.join(log_message, ""))
    end
  end
  
  @doc """
  Log price changes in a standardized format.
  
  ## Parameters
  - old_price: Previous price (Decimal or number)
  - new_price: New price (Decimal or number)
  """
  def log_price_change(old_price, new_price) do
    old_decimal = ensure_decimal(old_price)
    new_decimal = ensure_decimal(new_price)
    
    if D.compare(new_decimal, old_decimal) != :eq do
      percent_change = calculate_percent_change(old_decimal, new_decimal)
      change_str = format_percent_change(percent_change)
      
      Logger.info(
        "#{@price_prefix} Bitcoin price updated: $#{D.to_string(old_decimal)} -> $#{D.to_string(new_decimal)} (#{change_str})"
      )
    else
      Logger.debug(
        "#{@price_prefix} Bitcoin price unchanged at $#{D.to_string(new_decimal)}"
      )
    end
  end
  
  @doc """
  Log a wallet transaction in a standardized format.
  
  ## Parameters
  - type: Transaction type (:cash_deposit, :buy_bitcoin, :sell_bitcoin)
  - amount: Cash amount involved
  - btc_amount: Bitcoin amount involved (nil for cash deposits)
  - btc_price: Bitcoin price (nil for cash deposits)
  - cash_balance: New cash balance after transaction
  - bitcoin_balance: New Bitcoin balance after transaction
  """
  def log_transaction(type, amount, btc_amount, btc_price, cash_balance, bitcoin_balance) do
    case type do
      :cash_deposit ->
        Logger.info(
          "#{@wallet_prefix} Cash deposit: $#{amount} | New balance: $#{D.to_string(cash_balance)}"
        )
        
      :buy_bitcoin ->
        Logger.info(
          "#{@transaction_prefix} Bought #{btc_amount} BTC at $#{btc_price} for $#{amount} | " <>
          "Cash: $#{D.to_string(cash_balance)}, BTC: #{D.to_string(bitcoin_balance)}"
        )
        
      :sell_bitcoin ->
        Logger.info(
          "#{@transaction_prefix} Sold #{btc_amount} BTC at $#{btc_price} for $#{amount} | " <>
          "Cash: $#{D.to_string(cash_balance)}, BTC: #{D.to_string(bitcoin_balance)}"
        )
        
      _ ->
        Logger.info(
          "#{@wallet_prefix} Unknown transaction type: #{type} | " <>
          "Cash: $#{D.to_string(cash_balance)}, BTC: #{D.to_string(bitcoin_balance)}"
        )
    end
  end
  
  @doc """
  Log PubSub activities for debugging.
  
  ## Parameters
  - action: The PubSub action (:subscribe, :unsubscribe, :broadcast)
  - topic: The topic being operated on
  - details: Additional details (optional)
  """
  def log_pubsub(action, topic, details \\ nil) do
    details_str = if details, do: " | #{inspect(details)}", else: ""
    
    case action do
      :subscribe ->
        Logger.debug("PubSub: Subscribed to #{topic}#{details_str}")
        
      :unsubscribe ->
        Logger.debug("PubSub: Unsubscribed from #{topic}#{details_str}")
        
      :broadcast ->
        Logger.debug("PubSub: Broadcasting to #{topic}#{details_str}")
        
      _ ->
        Logger.debug("PubSub: Unknown action #{action} on #{topic}#{details_str}")
    end
  end
  
  @doc """
  Log an error with context information.
  
  ## Parameters
  - context: The context where the error occurred
  - error: The error that occurred
  - details: Additional context details (optional)
  """
  def log_error(context, error, details \\ nil) do
    details_str = if details, do: " | Context: #{inspect(details)}", else: ""
    
    Logger.error(
      "#{@error_prefix} #{context}: #{inspect(error)}#{details_str}"
    )
  end
  
  @doc """
  Log the start of a GenServer with configuration information.
  
  ## Parameters
  - module_name: The name of the GenServer module
  - config: Configuration parameters (optional)
  """
  def log_genserver_start(module_name, config \\ nil) do
    config_str = if config, do: " with config: #{inspect(config)}", else: ""
    Logger.info("#{module_name} starting#{config_str}...")
  end
  
  @doc """
  Log a scheduler event (recurring task, timer, etc.)
  
  ## Parameters
  - task: The task being scheduled
  - interval: The interval in milliseconds
  - details: Additional details (optional)
  """
  def log_scheduler(task, interval, details \\ nil) do
    details_str = if details, do: " | #{inspect(details)}", else: ""
    
    Logger.debug(
      "Scheduler: #{task} scheduled to run in #{interval}ms#{details_str}"
    )
  end
  
  defp sanitize_headers(headers) do
    Enum.map(headers, fn
      {name, _value} when name in ["X-CMC_PRO_API_KEY", "Authorization", "api-key", "key", "token"] ->
        {name, "[REDACTED]"}
      header ->
        header
    end)
  end
  
  defp calculate_percent_change(old_price, new_price) do
    if D.eq?(old_price, D.new(0)) do
      D.new(0)
    else
      D.mult(
        D.div(
          D.sub(new_price, old_price),
          old_price
        ),
        D.new(100)
      )
    end
  end
  
  defp format_percent_change(percent) do
    rounded = D.round(percent, 2)
    
    cond do
      D.gt?(rounded, D.new(0)) -> "+#{D.to_string(rounded)}%"
      D.lt?(rounded, D.new(0)) -> "#{D.to_string(rounded)}%"
      true -> "0.00%"
    end
  end
  defp ensure_decimal(nil), do: D.new(0)
  defp ensure_decimal(value) when is_struct(value, D), do: value
  defp ensure_decimal(value) when is_float(value), do: D.from_float(value)
  defp ensure_decimal(value) when is_integer(value), do: D.new(value)
  defp ensure_decimal(value) when is_binary(value), do: D.new(value)
  defp ensure_decimal(_), do: D.new(0)
end