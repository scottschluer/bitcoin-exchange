defmodule BitcoinExchange.Config.PubSubConfig do
  @moduledoc """
  Configuration values for PubSub topics.
  """

  @doc """
  PubSub topic for price updates.
  """
  def price_updates_topic, do: Application.get_env(:bitcoin_exchange, :pubsub)[:price_updates_topic] || "price_updates"

  @doc """
  PubSub topic for wallet updates.
  """
  def wallet_updates_topic, do: Application.get_env(:bitcoin_exchange, :pubsub)[:wallet_updates_topic] || "wallet_updates"
end