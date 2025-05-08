defmodule BitcoinExchange.Market do
  @moduledoc """
  The Market context handles market data and pricing information.

  This context is responsible for fetching, tracking, and processing
  cryptocurrency market data from external APIs.
  """

  alias BitcoinExchange.Market.Services.PriceTracker

  defdelegate get_current_data(), to: PriceTracker
end
