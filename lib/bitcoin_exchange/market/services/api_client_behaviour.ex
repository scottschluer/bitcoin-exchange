defmodule BitcoinExchange.Market.Services.ApiClientBehaviour do
  @moduledoc """
  Behaviour (interface) for cryptocurrency API clients.
  
  This module defines the contract that all API client implementations must follow.
  It allows for easily swapping between different HTTP client implementations
  while maintaining a consistent interface for the application.
  """

  @doc """
  Makes a GET request to the specified URL with headers.
  
  ## Parameters
  - url: The full URL to request
  - headers: List of {header_name, header_value} tuples
  
  ## Returns
  - {:ok, response_body} on success where response_body is a binary
  - {:error, reason} on failure
  """
  @callback get(url :: String.t(), headers :: list({String.t(), String.t()})) :: {:ok, String.t()} | {:error, term()}
  
  @doc """
  Makes a POST request to the specified URL with headers and body.
  
  ## Parameters
  - url: The full URL to request
  - headers: List of {header_name, header_value} tuples
  - body: Request body as string
  
  ## Returns
  - {:ok, response_body} on success where response_body is a binary
  - {:error, reason} on failure
  """
  @callback post(url :: String.t(), headers :: list({String.t(), String.t()}), body :: String.t()) :: {:ok, String.t()} | {:error, term()}
end