defmodule BitcoinExchange.Market.Services.ApiClientFactory do
  @moduledoc """
  Factory for creating API client instances.
  
  This module provides a simplified interface for obtaining API client 
  implementations that follow the ApiClientBehaviour.
  """
  
  alias BitcoinExchange.Config.ApiConfig

  @doc """
  Gets the configured API client implementation.
  
  This function returns the module itself, since our current implementations
  are stateless. This simplifies the API while still supporting future changes.
  
  ## Returns
  - A module that implements ApiClientBehaviour
  """
  def get_client do
    ApiConfig.client_implementation()
  end
end