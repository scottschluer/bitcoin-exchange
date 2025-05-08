defmodule BitcoinExchange.Utils.ValidationUtils do
  @moduledoc """
  Common validation utilities used across the application.
  
  This module provides functions for validating various types of data
  including bitcoin addresses, transaction IDs, and numeric values.
  """
  
  alias Decimal, as: D
  
  @doc """
  Validates a Bitcoin amount is positive and within reasonable limits.
  
  ## Parameters
  - amount: The Bitcoin amount to validate
  
  ## Returns
  - {:ok, amount} if valid
  - {:error, reason} if invalid
  """
  def validate_bitcoin_amount(amount) when is_nil(amount), do: {:error, "Bitcoin amount cannot be nil"}
  
  def validate_bitcoin_amount(amount) do
    decimal_amount = ensure_decimal(amount)
    
    cond do
      # Amount must be positive
      D.lt?(decimal_amount, D.new(0)) ->
        {:error, "Bitcoin amount must be positive"}
        
      # Amount must be reasonable (we use 21M as max which is Bitcoin's max supply)
      D.gt?(decimal_amount, D.new(21_000_000)) ->
        {:error, "Bitcoin amount exceeds maximum allowed"}
        
      # Amount must have at most 8 decimal places (1 satoshi precision)
      exceeds_precision?(decimal_amount, 8) ->
        {:error, "Bitcoin amount must have at most 8 decimal places"}
        
      true ->
        {:ok, decimal_amount}
    end
  end
  
  @doc """
  Validates a cash amount is positive and within reasonable limits.
  
  ## Parameters
  - amount: The cash amount to validate
  
  ## Returns
  - {:ok, amount} if valid
  - {:error, reason} if invalid
  """
  def validate_cash_amount(amount) when is_nil(amount), do: {:error, "Cash amount cannot be nil"}
  
  def validate_cash_amount(amount) do
    decimal_amount = ensure_decimal(amount)
    
    cond do
      # Amount must be positive
      D.lt?(decimal_amount, D.new(0)) ->
        {:error, "Cash amount must be positive"}
        
      # Amount must be reasonable (we use 1 billion as max for a virtual wallet)
      D.gt?(decimal_amount, D.new(1_000_000_000)) ->
        {:error, "Cash amount exceeds maximum allowed"}
        
      # Amount must have at most 2 decimal places (cents precision)
      exceeds_precision?(decimal_amount, 2) ->
        {:error, "Cash amount must have at most 2 decimal places"}
        
      true ->
        {:ok, decimal_amount}
    end
  end
  
  @doc """
  Validates a Bitcoin price is positive and within reasonable limits.
  
  ## Parameters
  - price: The Bitcoin price to validate
  
  ## Returns
  - {:ok, price} if valid
  - {:error, reason} if invalid
  """
  def validate_bitcoin_price(price) when is_nil(price), do: {:error, "Bitcoin price cannot be nil"}
  
  def validate_bitcoin_price(price) do
    decimal_price = ensure_decimal(price)
    
    cond do
      # Price must be positive
      D.lt?(decimal_price, D.new(0)) ->
        {:error, "Bitcoin price must be positive"}
        
      # Price must be reasonable (we use a million as max)
      D.gt?(decimal_price, D.new(1_000_000)) ->
        {:error, "Bitcoin price exceeds maximum allowed"}
        
      true ->
        {:ok, decimal_price}
    end
  end
  
  @doc """
  Validates a transaction ID.
  
  ## Parameters
  - transaction_id: The transaction ID to validate
  
  ## Returns
  - {:ok, transaction_id} if valid
  - {:error, reason} if invalid
  """
  def validate_transaction_id(nil), do: {:error, "Transaction ID cannot be nil"}
  
  def validate_transaction_id(transaction_id) do
    if valid_transaction_id_format?(transaction_id) do
      {:ok, transaction_id}
    else
      {:error, "Invalid transaction ID format"}
    end
  end
  
  @doc """
  Validates a timestamp is not in the future and is within reasonable bounds.
  
  ## Parameters
  - timestamp: The timestamp to validate
  
  ## Returns
  - {:ok, timestamp} if valid
  - {:error, reason} if invalid
  """
  def validate_timestamp(nil), do: {:error, "Timestamp cannot be nil"}
  
  def validate_timestamp(timestamp) when not is_struct(timestamp, DateTime),
    do: {:error, "Timestamp must be a DateTime"}
  
  def validate_timestamp(timestamp) do
    now = DateTime.utc_now()
    
    cond do
      # Timestamp should not be in the future (allow a small offset for clock differences)
      DateTime.diff(timestamp, now) > 60 ->
        {:error, "Timestamp cannot be in the future"}
        
      # Timestamp should not be too old (we use 10 years as a reasonable bound)
      DateTime.diff(now, timestamp) > 315_360_000 ->
        {:error, "Timestamp is too old"}
        
      true ->
        {:ok, timestamp}
    end
  end
  
  @doc """
  Validates a map has all required keys.
  
  ## Parameters
  - map: The map to validate
  - required_keys: A list of keys that must be present
  
  ## Returns
  - {:ok, map} if valid
  - {:error, reason} if invalid
  """
  def validate_required_keys(map, _required_keys) when not is_map(map),
    do: {:error, "Expected a map"}
  
  def validate_required_keys(map, required_keys) do
    missing_keys =
      required_keys
      |> Enum.filter(fn key -> !Map.has_key?(map, key) end)
    
    if Enum.empty?(missing_keys) do
      {:ok, map}
    else
      {:error, "Missing required keys: #{inspect(missing_keys)}"}
    end
  end
  
  @doc """
  Validates a value is within a specified range.
  
  ## Parameters
  - value: The value to validate
  - min: The minimum allowed value (optional)
  - max: The maximum allowed value (optional)
  
  ## Returns
  - {:ok, value} if valid
  - {:error, reason} if invalid
  """
  def validate_range(nil, _min, _max), do: {:error, "Value cannot be nil"}
  
  def validate_range(value, min, max) do
    decimal_value = ensure_decimal(value)
    
    cond do
      min && D.lt?(decimal_value, ensure_decimal(min)) ->
        {:error, "Value must be at least #{min}"}
        
      max && D.gt?(decimal_value, ensure_decimal(max)) ->
        {:error, "Value must be at most #{max}"}
        
      true ->
        {:ok, decimal_value}
    end
  end
  
  defp exceeds_precision?(decimal, max_precision) do
    decimal_str = D.to_string(decimal)
    
    case String.split(decimal_str, ".") do
      [_integer_part, decimal_part] ->
        String.length(decimal_part) > max_precision
        
      [_integer_part] ->
        false
    end
  end
  
  defp valid_transaction_id_format?(transaction_id) do
    case String.split(transaction_id, "-") do
      [prefix, timestamp, random, checksum] ->
        valid_prefix?(prefix) && valid_timestamp_format?(timestamp) &&
          valid_random_format?(random) && valid_checksum_format?(checksum)
        
      _ ->
        false
    end
  end
  
  defp valid_prefix?(prefix) do
    prefix in ["BUY", "SEL", "ADD", "TXN"]
  end
  
  defp valid_timestamp_format?(timestamp) do
    case Integer.parse(timestamp) do
      {_, ""} -> String.length(timestamp) == 14
      _ -> false
    end
  end
  
  defp valid_random_format?(random) do
    String.length(random) == 10 && String.match?(random, ~r/^[0-9A-F]+$/)
  end
  
  defp valid_checksum_format?(checksum) do
    String.length(checksum) == 1 && String.match?(checksum, ~r/^[0-9A-F]$/)
  end
  
  defp ensure_decimal(nil), do: D.new(0)
  defp ensure_decimal(value) when is_struct(value, D), do: value
  defp ensure_decimal(value) when is_float(value), do: D.from_float(value)
  defp ensure_decimal(value) when is_integer(value), do: D.new(value)
  defp ensure_decimal(value) when is_binary(value), do: D.new(value)
  defp ensure_decimal(_), do: D.new(0)
end