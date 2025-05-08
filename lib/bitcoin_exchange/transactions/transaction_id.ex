defmodule BitcoinExchange.Transactions.TransactionID do
  @moduledoc """
  Provides functions for generating cryptographically secure transaction IDs
  that comply with financial industry standards.

  ## Examples

      # Generate a transaction ID for a buy transaction
      iex> alias BitcoinExchange.Transactions.TransactionID
      iex> id = TransactionID.generate("buy")
      iex> String.starts_with?(id, "BUY-")
      true
      iex> TransactionID.valid?(id)
      true

      # Generate a transaction ID for a sell transaction
      iex> id = TransactionID.generate("sell")
      iex> String.starts_with?(id, "SEL-")
      true

      # Verify transaction ID format
      iex> id = "BUY-20230615123456-A7B3C9D1E5-F"
      iex> TransactionID.valid?(id)
      true
      iex> TransactionID.valid?("INVALID-FORMAT")
      false
  """

  @doc """
  Generates a unique transaction ID with the following properties:
  - Starts with a prefix based on transaction type (BUY/SEL/ADD)
  - Includes a timestamp component (YYYYMMDDHHmmss)
  - Contains a random component with high entropy
  - Includes a checksum digit
  - Format: PREFIX-TIMESTAMP-RANDOM-CHECKSUM

  ## Examples

      iex> TransactionID.generate("buy")
      "BUY-20230615123456-A7B3C9D1E5-F"
  """
  @spec generate(String.t()) :: String.t()
  def generate(transaction_type) do
    prefix = get_transaction_prefix(transaction_type)
    timestamp = generate_timestamp()
    random = generate_random_component()
    content = "#{prefix}-#{timestamp}-#{random}"
    checksum = generate_checksum(content)

    "#{content}-#{checksum}"
  end

  @doc """
  Validates if a transaction ID is properly formatted and the checksum is correct.

  ## Examples

      iex> TransactionID.valid?("BUY-20230615123456-A7B3C9D1E5-F")
      true
  """
  @spec valid?(String.t()) :: boolean()
  def valid?(transaction_id) do
    case String.split(transaction_id, "-") do
      [prefix, timestamp, random, checksum] ->
        content = "#{prefix}-#{timestamp}-#{random}"
        expected_checksum = generate_checksum(content)
        checksum == expected_checksum && valid_prefix?(prefix) && valid_timestamp?(timestamp)

      _ ->
        false
    end
  end

  # Gets the appropriate prefix based on transaction type
  defp get_transaction_prefix(type) do
    case String.downcase(type) do
      "buy" -> "BUY"
      "sell" -> "SEL"
      "add_funds" -> "ADD"
      # Fallback for unexpected transaction types
      _ -> "TXN"
    end
  end

  # Generates a timestamp in format YYYYMMDDHHmmss
  defp generate_timestamp do
    DateTime.utc_now()
    |> Calendar.strftime("%Y%m%d%H%M%S")
  end

  # Generates a cryptographically secure random component (10 hex chars = 40 bits)
  defp generate_random_component do
    :crypto.strong_rand_bytes(5)
    |> Base.encode16(case: :upper)
  end

  # Generates a simple checksum (single hex digit) for basic error detection
  defp generate_checksum(content) do
    :crypto.hash(:sha256, content)
    |> binary_part(0, 1)
    |> Base.encode16(case: :upper)
    |> binary_part(0, 1)
  end

  # Validates if the prefix is a known/expected type
  defp valid_prefix?(prefix) do
    prefix in ["BUY", "SEL", "ADD", "TXN"]
  end

  # Validates if the timestamp is properly formatted
  defp valid_timestamp?(timestamp) do
    case Integer.parse(timestamp) do
      {_, ""} -> String.length(timestamp) == 14
      _ -> false
    end
  end
end
