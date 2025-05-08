defmodule BitcoinExchange.Market.Services.BaseApiClient do
  @moduledoc """
  Base module for cryptocurrency API clients.
  
  Provides common functionality for all API client implementations,
  such as JSON parsing and error handling.
  """
  
  require Logger
  
  @doc """
  Parses a JSON response body.
  
  ## Parameters
  - body: Response body as string
  
  ## Returns
  - {:ok, parsed_data} on success where parsed_data is a map
  - {:error, reason} on failure
  """
  def parse_json(body) when is_binary(body) do
    try do
      {:ok, Jason.decode!(body)}
    rescue
      e ->
        Logger.error("Error parsing JSON response: #{inspect(e)}")
        Logger.debug("Response body: #{inspect(body)}")
        {:error, "Failed to parse JSON response"}
    end
  end
  
  def parse_json(body) do
    Logger.error("Received non-binary response body: #{inspect(body)}")
    {:error, "Invalid response format"}
  end
  
  @doc """
  Logs an API request.
  
  ## Parameters
  - method: HTTP method (e.g., "GET", "POST")
  - url: Request URL
  - headers: Request headers (sensitive data like API keys will be redacted)
  - body: Request body (optional)
  """
  def log_request(method, url, headers, body \\ nil) do
    safe_headers = redact_sensitive_headers(headers)
    
    log_message = "API Request: #{method} #{url}"
    
    Logger.debug(fn ->
      [
        log_message,
        "\nHeaders: #{inspect(safe_headers)}",
        if(body, do: "\nBody: #{inspect(body)}", else: "")
      ]
    end)
  end
  
  @doc """
  Logs an API response.
  
  ## Parameters
  - status: HTTP status code or :error
  - body_or_error: Response body or error reason
  """
  def log_response(:error, reason) do
    Logger.error("API Request failed: #{inspect(reason)}")
  end
  
  def log_response(status, body) when is_integer(status) do
    success = status >= 200 and status < 300
    
    if success do
      Logger.debug("API Response: HTTP #{status}")
    else
      Logger.warning("API Response: HTTP #{status} - #{inspect(body)}")
    end
  end
  
  defp redact_sensitive_headers(headers) do
    Enum.map(headers, fn
      {"X-CMC_PRO_API_KEY", value} -> {"X-CMC_PRO_API_KEY", redact_string(value)}
      {"Authorization", value} -> {"Authorization", redact_string(value)}
      {"api-key", value} -> {"api-key", redact_string(value)}
      header -> header
    end)
  end
  
  defp redact_string(value) when is_binary(value) and byte_size(value) > 8 do
    first = String.slice(value, 0, 4)
    last = String.slice(value, -4, 4)
    "#{first}...#{last}"
  end
  
  defp redact_string(_), do: "***REDACTED***"
end