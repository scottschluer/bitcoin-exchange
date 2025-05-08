defmodule BitcoinExchange.Market.Services.CurlApiClient do
  @moduledoc """
  API client implementation using system curl command.
  
  This implementation uses the system curl command to make HTTP requests,
  which has proven reliable for CoinMarketCap API access.
  """
  
  @behaviour BitcoinExchange.Market.Services.ApiClientBehaviour
  
  require Logger
  alias BitcoinExchange.Config.ApiConfig
  
  @doc """
  Makes a GET request using system curl.
  
  ## Parameters
  - url: The full URL to request
  - headers: List of {header_name, header_value} tuples
  
  ## Returns
  - {:ok, response_body} on success
  - {:error, reason} on failure
  """
  @impl true
  def get(url, headers) do
    Logger.debug("Making curl GET request to: #{url}")
    
    # Convert headers to curl format
    header_args = headers_to_curl_args(headers)
    
    # Execute curl command
    case System.cmd("curl", ["-s" | header_args] ++ [url]) do
      {response, 0} ->
        Logger.debug("Curl command succeeded")
        {:ok, response}
        
      {error, code} ->
        Logger.error("Curl command failed with code #{code}: #{error}")
        {:error, "Curl failed with code #{code}: #{error}"}
    end
  rescue
    e ->
      Logger.error("Error using system curl: #{inspect(e)}")
      {:error, "System error: #{inspect(e)}"}
  end
  
  @doc """
  Makes a POST request using system curl.
  
  ## Parameters
  - url: The full URL to request
  - headers: List of {header_name, header_value} tuples
  - body: Request body as string
  
  ## Returns
  - {:ok, response_body} on success
  - {:error, reason} on failure
  """
  @impl true
  def post(url, headers, body) do
    Logger.debug("Making curl POST request to: #{url}")
    
    # Convert headers to curl format
    header_args = headers_to_curl_args(headers)
    
    # Execute curl command with POST data
    args = ["-s", "-X", "POST"] ++ header_args ++ ["-d", body, url]
    
    case System.cmd("curl", args) do
      {response, 0} ->
        Logger.debug("Curl POST command succeeded")
        {:ok, response}
        
      {error, code} ->
        Logger.error("Curl POST command failed with code #{code}: #{error}")
        {:error, "Curl failed with code #{code}: #{error}"}
    end
  rescue
    e ->
      Logger.error("Error using system curl for POST: #{inspect(e)}")
      {:error, "System error: #{inspect(e)}"}
  end
  
  # Converts a list of {header_name, header_value} tuples to curl command arguments
  defp headers_to_curl_args(headers) do
    Enum.flat_map(headers, fn {name, value} ->
      ["-H", "#{name}: #{value}"]
    end)
  end

  @doc """
  Makes a GET request using a direct IP address if needed.
  
  This is particularly useful for CoinMarketCap API when experiencing DNS issues.
  
  ## Parameters
  - url: The full URL to request 
  - headers: List of {header_name, header_value} tuples
  
  ## Returns
  - {:ok, response_body} on success
  - {:error, reason} on failure
  """
  def get_with_direct_ip(url, headers) do
    # Try normal GET first
    case get(url, headers) do
      {:ok, response} ->
        {:ok, response}
        
      {:error, reason} ->
        Logger.warning("Regular GET failed, trying direct IP approach: #{inspect(reason)}")
        
        # Use one of the known IP addresses
        ip = Enum.random(ApiConfig.allowed_ips())
        direct_url = String.replace(url, "https://pro-api.coinmarketcap.com", "https://#{ip}")
        
        # Make sure Host header is present for direct IP access
        headers_with_host = 
          if Enum.any?(headers, fn {name, _} -> name == "Host" end) do
            headers
          else
            [{"Host", "pro-api.coinmarketcap.com"} | headers]
          end
        
        get(direct_url, headers_with_host)
    end
  end
end