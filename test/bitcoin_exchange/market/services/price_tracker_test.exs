defmodule BitcoinExchange.Market.Services.PriceTrackerTest do
  use BitcoinExchange.PriceTrackerCase

  alias BitcoinExchange.Market.Services.PriceTracker
  alias BitcoinExchange.Test.Mocks.MockPriceClient

  setup do
    MockPriceClient.start_link()
    :ok
  end

  describe "price data fetching and processing" do
    setup do
      MockPriceClient.reset()

      {:ok, pid} = start_test_price_tracker(price_client: MockPriceClient)

      {:ok, %{pid: pid}}
    end

    test "successfully processes API data and updates state", %{pid: pid} do
      initial_data = {:ok, MockPriceClient.default_success_response()}
      MockPriceClient.set_responses([initial_data])

      # Trigger a price update
      Process.send(pid, :update_price, [:nosuspend])
      :timer.sleep(50)

      price_data = PriceTracker.get_current_data()

      assert Decimal.eq?(price_data.bitcoin_price, Decimal.new("50000"))
      assert price_data.consecutive_failures == 0
      assert length(price_data.history) == 1

      call_history = MockPriceClient.get_call_history()
      assert length(call_history) == 1
    end

    test "maintains price history with the most recent prices first", %{pid: pid} do
      price1 = MockPriceClient.response_with(%{price: 50000.0, timestamp: DateTime.utc_now()})

      price2 =
        MockPriceClient.response_with(%{
          price: 51000.0,
          timestamp: DateTime.add(DateTime.utc_now(), 3600)
        })

      price3 =
        MockPriceClient.response_with(%{
          price: 49500.0,
          timestamp: DateTime.add(DateTime.utc_now(), 7200)
        })

      MockPriceClient.set_responses([
        {:ok, price1},
        {:ok, price2},
        {:ok, price3}
      ])

      Process.send(pid, :update_price, [:nosuspend])
      :timer.sleep(50)
      Process.send(pid, :update_price, [:nosuspend])
      :timer.sleep(50)
      Process.send(pid, :update_price, [:nosuspend])
      :timer.sleep(50)

      price_data = PriceTracker.get_current_data()

      assert Decimal.eq?(price_data.bitcoin_price, Decimal.new("49500"))

      assert length(price_data.history) == 3

      [first, second, third] = price_data.history
      assert Decimal.eq?(Decimal.new("#{first.price}"), Decimal.new("49500"))
      assert Decimal.eq?(Decimal.new("#{second.price}"), Decimal.new("51000"))
      assert Decimal.eq?(Decimal.new("#{third.price}"), Decimal.new("50000"))
    end

    test "handles API errors by incrementing failure count", %{pid: pid} do
      MockPriceClient.set_responses([{:error, "API failure"}])

      Process.send(pid, :update_price, [:nosuspend])
      :timer.sleep(50)

      price_data = PriceTracker.get_current_data()

      assert price_data.consecutive_failures == 1

      assert Decimal.eq?(price_data.bitcoin_price, Decimal.new("0"))
    end
  end
end
