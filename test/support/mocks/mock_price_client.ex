defmodule BitcoinExchange.Test.Mocks.MockPriceClient do
  @moduledoc """
  Mock implementation of the CoinMarketCapClient for testing.
  
  This module mocks the behavior of the CoinMarketCapClient
  for unit testing without making actual API calls. It supports
  different response scenarios to test various code paths.
  """
  
  # State tracking for tests
  use Agent
  
  @doc """
  Starts the MockPriceClient agent for tracking calls and responses
  """
  def start_link do
    Agent.start_link(
      fn -> 
        %{
          call_count: 0,
          responses: [{:ok, default_success_response()}],
          call_history: []
        } 
      end,
      name: __MODULE__
    )
  end
  
  @doc """
  Resets the mock to its initial state
  """
  def reset do
    if Process.whereis(__MODULE__) do
      Agent.update(__MODULE__, fn _ -> 
        %{
          call_count: 0,
          responses: [{:ok, default_success_response()}],
          call_history: []
        }
      end)
    else
      start_link()
    end
  end
  
  @doc """
  Sets up a sequence of responses for the mock to return
  
  ## Parameters
  - responses: List of responses to return in sequence
  """
  def set_responses(responses) when is_list(responses) do
    Agent.update(__MODULE__, fn state -> %{state | responses: responses} end)
  end
  
  @doc """
  Returns the history of calls made to the mock
  """
  def get_call_history do
    Agent.get(__MODULE__, fn state -> state.call_history end)
  end
  
  @doc """
  Returns the number of times the mock has been called
  """
  def get_call_count do
    Agent.get(__MODULE__, fn state -> state.call_count end)
  end
  
  @doc """
  Mock implementation of get_crypto_quote_by_id that returns predefined test data.
  
  ## Parameters
  - id: The cryptocurrency ID
  - convert_to: The currency to convert to
  
  ## Returns
  - Response based on the configured sequence
  """
  def get_crypto_quote_by_id(id, convert_to) do
    # Start the agent if it's not already running
    if !Process.whereis(__MODULE__), do: start_link()
    
    # Record this call
    Agent.update(__MODULE__, fn state -> 
      new_history = state.call_history ++ [{:get_crypto_quote_by_id, id, convert_to}]
      %{state | call_count: state.call_count + 1, call_history: new_history} 
    end)
    
    # Get the next response
    response = Agent.get_and_update(__MODULE__, fn state -> 
      case state.responses do
        [next_response | rest] -> 
          {next_response, %{state | responses: rest ++ [next_response]}}
        [] -> 
          default = {:ok, default_success_response()}
          {default, state}
      end
    end)
    
    response
  end
  
  @doc """
  Default success response with standard test values
  """
  def default_success_response do
    %{
      price: 50000.0,
      volume_24h: 30000000000.0,
      market_cap: 950000000000.0,
      percent_change_1h: 0.5,
      percent_change_24h: 2.3,
      percent_change_7d: 5.7,
      timestamp: DateTime.utc_now()
    }
  end
  
  @doc """
  Creates a response with specified values, using defaults for unspecified ones
  """
  def response_with(overrides) when is_map(overrides) do
    Map.merge(default_success_response(), overrides)
  end
end