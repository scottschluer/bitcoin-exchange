defmodule BitcoinExchange.PriceTrackerCase do
  @moduledoc """
  Test case for testing PriceTracker with mocked dependencies.
  
  This module helps isolate tests involving the PriceTracker singleton 
  GenServer by temporarily replacing its process during testing.
  """
  
  use ExUnit.CaseTemplate
  alias BitcoinExchange.Market.Services.PriceTracker
  
  using do
    quote do
      # Import convenience functions
      import BitcoinExchange.PriceTrackerCase
    end
  end
  
  setup do
    # Store original PID if it exists
    original_pid = Process.whereis(PriceTracker)
    
    # Unregister the name if process exists
    if original_pid do
      Process.unregister(PriceTracker)
    end
    
    # Return a teardown function that will restore the original process registration
    on_exit(fn ->
      # Kill any test process still registered with this name
      test_pid = Process.whereis(PriceTracker)
      if test_pid do
        Process.exit(test_pid, :normal)
        Process.unregister(PriceTracker)
      end
      
      # Re-register the original PID if it existed and is still alive
      if original_pid && Process.alive?(original_pid) do
        Process.register(original_pid, PriceTracker)
      end
    end)
    
    :ok
  end
  
  @doc """
  Start a test instance of PriceTracker with the given options.
  
  This function temporarily replaces the global PriceTracker instance
  with a test instance that has mocked dependencies.
  
  ## Parameters
  - opts: Options to pass to PriceTracker.start_link/1
  
  ## Returns
  - {:ok, pid} on success
  - {:error, reason} on failure
  """
  def start_test_price_tracker(opts \\ []) do
    PriceTracker.start_link(opts)
  end
end