defmodule BitcoinExchange.Dashboard.UIHelpers do
  @moduledoc """
  UI helper functions for the dashboard and related components.

  This module contains all the formatting and UI-related helper functions
  that were previously part of the DashboardLive module, centralized
  for better organization and reuse across components.
  """

  alias BitcoinExchange.Utils.DecimalUtils, as: DU

  @doc """
  Formats a currency value with $ symbol, thousands separators, and 2 decimal places.

  Handles Decimal, float, integer, and string inputs.

  ## Examples
      iex> format_currency(1234.56)
      "$1,234.56"

      iex> format_currency(Decimal.new("1000.5"))
      "$1,000.50"
  """
  def format_currency(amount) do
    # Handle both Decimal and float/integer values
    decimal_str =
      cond do
        # If it's a Decimal, convert to string with 2 decimal places
        is_struct(amount, Decimal) ->
          Decimal.round(amount, 2) |> Decimal.to_string()

        # If it's a float or integer, format with 2 decimal places
        is_number(amount) ->
          :erlang.float_to_binary(amount * 1.0, decimals: 2)

        # Handle string input (just in case)
        is_binary(amount) ->
          if String.contains?(amount, ".") do
            amount
          else
            "#{amount}.00"
          end

        # Fallback for other cases
        true ->
          "0.00"
      end

    # Split into integer and decimal parts
    parts = String.split(decimal_str, ".")
    int_part = Enum.at(parts, 0)
    dec_part = if length(parts) > 1, do: Enum.at(parts, 1), else: "00"

    # Ensure decimal part has exactly 2 digits
    dec_part = String.pad_trailing(String.slice(dec_part, 0, 2), 2, "0")

    # Add commas for thousands separators (handle negative numbers)
    {sign, abs_int_part} =
      if String.starts_with?(int_part, "-") do
        {"-", String.slice(int_part, 1..-1//1)}
      else
        {"", int_part}
      end

    int_with_commas =
      abs_int_part
      |> String.to_integer()
      |> Integer.to_string()
      |> add_thousands_separators()

    "#{sign}$#{int_with_commas}.#{dec_part}"
  end

  @doc """
  Helper function to add thousands separators to a number string.

  ## Examples
      iex> add_thousands_separators("1234567")
      "1,234,567"
  """
  def add_thousands_separators(number_string) do
    number_string
    |> String.graphemes()
    |> Enum.reverse()
    |> Enum.chunk_every(3)
    |> Enum.map(&Enum.join/1)
    |> Enum.join(",")
    |> String.reverse()
  end

  @doc """
  Formats a Bitcoin amount with 8 decimal places.

  ## Examples
      iex> format_btc(1.23456789)
      "1.23456789"
  """
  def format_btc(amount) do
    "#{:erlang.float_to_binary(amount, decimals: 8)}"
  end

  @doc """
  Returns a user-friendly label for a transaction type.

  ## Examples
      iex> transaction_type_label("buy")
      "Buy Bitcoin"
  """
  def transaction_type_label("buy"), do: "Buy Bitcoin"
  def transaction_type_label("sell"), do: "Sell Bitcoin"
  def transaction_type_label("add_funds"), do: "Add Funds"

  @doc """
  Returns a CSS class for the background color of a transaction based on its type.

  ## Examples
      iex> transaction_background_color("buy")
      "bg-green-100 dark:bg-green-900/30"
  """
  def transaction_background_color("buy"),
    do: "bg-green-100 dark:bg-green-900/30"

  def transaction_background_color("sell"),
    do: "bg-red-100 dark:bg-red-900/30"

  def transaction_background_color("add_funds"),
    do: "bg-blue-100 dark:bg-blue-900/30"

  @doc """
  Formats a percentage value with a % symbol and handles Decimal values.

  ## Examples
      iex> format_decimal_percentage(Decimal.new("5.25"))
      "5.25%"
  """
  def format_decimal_percentage(percent) do
    # Convert to absolute value and format
    abs_value = DU.abs(percent)

    # Format with two decimal places
    value_str =
      cond do
        is_struct(abs_value, Decimal) ->
          Decimal.round(abs_value, 2) |> Decimal.to_string()

        is_number(abs_value) ->
          :erlang.float_to_binary(abs_value * 1.0, decimals: 2)

        true ->
          "0.0"
      end

    "#{value_str}%"
  end

  @doc """
  Calculate previous total value by working backward from the current market conditions.
  """
  def calculate_previous_total_value(total_value, bitcoin_price, previous_price, bitcoin_balance) do
    # Calculate price difference
    price_diff = DU.sub(bitcoin_price, previous_price)

    # Calculate value change
    value_change = DU.mult(price_diff, bitcoin_balance)

    # Subtract from total to get previous value
    DU.sub(total_value, value_change)
  end

  @doc """
  Calculate previous bitcoin value in the same way.
  """
  def calculate_previous_bitcoin_value(
        bitcoin_value,
        bitcoin_price,
        previous_price,
        bitcoin_balance
      ) do
    # Same calculation as for total value
    calculate_previous_total_value(bitcoin_value, bitcoin_price, previous_price, bitcoin_balance)
  end

  @doc """
  Format transaction ID for display in UI (first 8 chars followed by ... and last 4 chars).

  ## Examples
      iex> format_transaction_id("1234567890abcdef")
      "12345678...cdef"
  """
  def format_transaction_id(transaction_id) do
    cond do
      is_nil(transaction_id) ->
        "N/A"

      String.length(transaction_id) <= 12 ->
        transaction_id

      true ->
        first = String.slice(transaction_id, 0..7)
        last = String.slice(transaction_id, -4..-1)
        "#{first}...#{last}"
    end
  end

  @doc """
  Returns a CSS class for animating value changes based on comparison.

  ## Examples
      iex> get_animation_class(100, 90)
      "animate-increase"
  """
  def get_animation_class(current, previous) do
    cond do
      current > previous -> "animate-increase"
      current < previous -> "animate-decrease"
      true -> ""
    end
  end

  @doc """
  Returns a CSS class for price changes based on whether they're positive or negative.

  ## Examples
      iex> get_color_class_for_change(Decimal.new("0.5"))
      "bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-300"
  """
  def get_color_class_for_change(change) do
    cond do
      is_nil(change) ->
        "bg-gray-100 text-gray-800 dark:bg-gray-800 dark:text-gray-300"

      DU.gte?(change, 0) ->
        "bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-300"

      true ->
        "bg-red-100 text-red-800 dark:bg-red-900/30 dark:text-red-300"
    end
  end
end
