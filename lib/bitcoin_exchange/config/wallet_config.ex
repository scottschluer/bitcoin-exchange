defmodule BitcoinExchange.Config.WalletConfig do
  @moduledoc """
  Configuration values for the wallet system.
  """

  @doc """
  Initial cash balance for new wallets.
  """
  def initial_balance, do: Application.get_env(:bitcoin_exchange, :wallet)[:initial_balance] || 10_000

  @doc """
  Initial bitcoin balance for new wallets.
  """
  def initial_bitcoin_balance, do: Application.get_env(:bitcoin_exchange, :wallet)[:initial_bitcoin_balance] || 0

  @doc """
  PubSub topic for wallet updates.
  """
  def pubsub_topic, do: Application.get_env(:bitcoin_exchange, :wallet)[:pubsub_topic] || "wallet_updates"

  @doc """
  GenServer call timeout in milliseconds.
  """
  def genserver_timeout, do: Application.get_env(:bitcoin_exchange, :wallet)[:genserver_timeout] || 30_000
end