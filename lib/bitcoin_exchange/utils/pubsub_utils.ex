defmodule BitcoinExchange.Utils.PubSubUtils do
  @moduledoc """
  Utility functions for working with Phoenix PubSub.
  
  This module provides helper functions for common PubSub operations
  like broadcasting events and subscribing to topics.
  """
  
  alias Phoenix.PubSub
  require Logger
  
  @pubsub_module BitcoinExchange.PubSub
  
  @doc """
  Subscribe to a topic with optional prefix.
  
  ## Parameters
  - topic: The base topic to subscribe to
  - prefix: Optional prefix to add to the topic (default: nil)
  
  ## Returns
  - :ok on success
  - {:error, term} on failure
  """
  def subscribe(topic, prefix \\ nil) do
    full_topic = get_full_topic(topic, prefix)
    
    try do
      Logger.debug("Subscribing to topic: #{full_topic}")
      PubSub.subscribe(@pubsub_module, full_topic)
    rescue
      e ->
        Logger.error("Failed to subscribe to topic #{full_topic}: #{inspect(e)}")
        {:error, "Failed to subscribe"}
    end
  end
  
  @doc """
  Unsubscribe from a topic with optional prefix.
  
  ## Parameters
  - topic: The base topic to unsubscribe from
  - prefix: Optional prefix to add to the topic (default: nil)
  
  ## Returns
  - :ok on success
  - {:error, term} on failure
  """
  def unsubscribe(topic, prefix \\ nil) do
    full_topic = get_full_topic(topic, prefix)
    
    try do
      Logger.debug("Unsubscribing from topic: #{full_topic}")
      PubSub.unsubscribe(@pubsub_module, full_topic)
    rescue
      e ->
        Logger.error("Failed to unsubscribe from topic #{full_topic}: #{inspect(e)}")
        {:error, "Failed to unsubscribe"}
    end
  end
  
  @doc """
  Broadcast a message to all subscribers of a topic with optional prefix.
  
  ## Parameters
  - topic: The base topic to broadcast to
  - message: The message to broadcast
  - prefix: Optional prefix to add to the topic (default: nil)
  
  ## Returns
  - :ok on success
  - {:error, term} on failure
  """
  def broadcast(topic, message, prefix \\ nil) do
    full_topic = get_full_topic(topic, prefix)
    
    try do
      Logger.debug("Broadcasting to topic: #{full_topic}")
      PubSub.broadcast(@pubsub_module, full_topic, message)
    rescue
      e ->
        Logger.error("Failed to broadcast to topic #{full_topic}: #{inspect(e)}")
        {:error, "Failed to broadcast"}
    end
  end
  
  @doc """
  Broadcast a message locally to all subscribers of a topic with optional prefix.
  
  ## Parameters
  - topic: The base topic to broadcast to
  - message: The message to broadcast
  - prefix: Optional prefix to add to the topic (default: nil)
  
  ## Returns
  - :ok on success
  - {:error, term} on failure
  """
  def broadcast_local(topic, message, prefix \\ nil) do
    full_topic = get_full_topic(topic, prefix)
    
    try do
      Logger.debug("Broadcasting locally to topic: #{full_topic}")
      PubSub.local_broadcast(@pubsub_module, full_topic, message)
    rescue
      e ->
        Logger.error("Failed to broadcast locally to topic #{full_topic}: #{inspect(e)}")
        {:error, "Failed to broadcast locally"}
    end
  end
  
  @doc """
  Get a list of known subscribers for a topic.
  This is primarily useful for debug and testing.
  
  ## Parameters
  - topic: The topic to get subscribers for
  - prefix: Optional prefix to add to the topic (default: nil)
  
  ## Returns
  - List of subscribers on success
  - {:error, term} on failure
  """
  def list_subscribers(topic, prefix \\ nil) do
    full_topic = get_full_topic(topic, prefix)
    
    try do
      Registry.lookup(Phoenix.PubSub.Registry, {Phoenix.PubSub, @pubsub_module, full_topic})
      |> Enum.map(fn {pid, _} -> pid end)
    rescue
      e ->
        Logger.error("Failed to list subscribers for topic #{full_topic}: #{inspect(e)}")
        {:error, "Failed to list subscribers"}
    end
  end
  
  # Helper to get the full topic name with optional prefix
  defp get_full_topic(topic, nil), do: topic
  defp get_full_topic(topic, prefix), do: "#{prefix}:#{topic}"
  
  @doc """
  Common topic names used in the application.
  """
  def topics do
    %{
      price_updates: "price_updates",
      wallet_updates: "wallet_updates",
      transaction_updates: "transaction_updates"
    }
  end
end