defmodule BitcoinExchange.Config.PriceTrackerConfig do
  @moduledoc """
  Configuration values for the price tracking system.
  """

  @doc """
  Time in milliseconds between price updates.
  """
  def update_interval, do: Application.get_env(:bitcoin_exchange, :price_tracker)[:update_interval] || 60_000

  @doc """
  Initial delay in milliseconds before the first price update.
  """
  def initial_update_delay, do: Application.get_env(:bitcoin_exchange, :price_tracker)[:initial_update_delay] || 2_000

  @doc """
  Maximum backoff interval in milliseconds for retries.
  """
  def max_backoff_interval, do: Application.get_env(:bitcoin_exchange, :price_tracker)[:max_backoff_interval] || 1_800_000

  @doc """
  CoinMarketCap ID for Bitcoin.
  """
  def bitcoin_id, do: Application.get_env(:bitcoin_exchange, :price_tracker)[:bitcoin_id] || 1

  @doc """
  Cache validity period in seconds.
  """
  def cache_valid_seconds, do: Application.get_env(:bitcoin_exchange, :price_tracker)[:cache_valid_seconds] || 3600

  @doc """
  PubSub topic for price updates.
  """
  def pubsub_topic, do: Application.get_env(:bitcoin_exchange, :price_tracker)[:pubsub_topic] || "price_updates"

  @doc """
  GenServer call timeout in milliseconds.
  """
  def genserver_timeout, do: Application.get_env(:bitcoin_exchange, :price_tracker)[:genserver_timeout] || 30_000

  @doc """
  Price history limit (number of data points to keep).
  """
  def history_limit, do: Application.get_env(:bitcoin_exchange, :price_tracker)[:history_limit] || 287
end