defmodule BitcoinExchange.Config.TransactionConfig do
  @moduledoc """
  Configuration values for transaction handling.
  """

  @doc """
  Minimum purchase amount in USD.
  """
  def min_purchase_amount, do: Application.get_env(:bitcoin_exchange, :transaction)[:min_purchase_amount] || 0.01

  @doc """
  Minimum sell amount in BTC.
  """
  def min_sell_amount, do: Application.get_env(:bitcoin_exchange, :transaction)[:min_sell_amount] || 0.00000001

  @doc """
  Threshold for determining if a buy operation is a "max" operation.
  The difference must be less than this value to be considered max.
  """
  def buy_max_threshold, do: Application.get_env(:bitcoin_exchange, :transaction)[:buy_max_threshold] || 0.01

  @doc """
  Error message for insufficient funds during buy operations.
  """
  def insufficient_funds_message, do: "Insufficient funds for this purchase"

  @doc """
  Error message for insufficient bitcoin during sell operations.
  """
  def insufficient_bitcoin_message, do: "Insufficient Bitcoin available"

  @doc """
  Error message for minimum purchase amount.
  """
  def min_purchase_message, do: "Minimum purchase amount is $#{min_purchase_amount()}"

  @doc """
  Error message for minimum sell amount.
  """
  def min_sell_message, do: "Minimum sell amount is #{min_sell_amount()} BTC"
end