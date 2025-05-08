defmodule BitcoinExchangeWeb.Live.Components.ChartComponent do
  @moduledoc """
  LiveView component for the Bitcoin price chart.

  This component wraps the price chart functionality and handles:
  - Pushing mock data to the client-side chart hook
  """

  use BitcoinExchangeWeb, :live_component
  require Logger

  @impl true
  def mount(socket) do
    Logger.info("Mounting ChartComponent")
    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    Logger.info("Updating ChartComponent with id: #{assigns[:id] || "not set"}")

    socket = assign(socket, assigns)

    socket =
      if assigns[:id] do
        Logger.info("Using existing id: #{assigns[:id]}")
        socket
      else
        id = "chart-#{:rand.uniform(1000)}"
        Logger.info("Generated new id: #{id}")
        assign(socket, id: id)
      end

    socket =
      if assigns[:chart_id] do
        Logger.info("Using existing chart_id: #{assigns[:chart_id]}")
        socket
      else
        chart_id = "price-chart-#{socket.assigns.id}"
        Logger.info("Generated new chart_id: #{chart_id}")
        assign(socket, chart_id: chart_id)
      end

    socket = 
      if connected?(socket) do
        Logger.info("LiveView connected")

        now = DateTime.utc_now()

        sample_data =
          Enum.map(0..288, fn i ->
            timestamp = DateTime.add(now, -i * 300, :second)
            price = 50000 + :rand.uniform(5000)

            %{
              time: DateTime.to_unix(timestamp) * 1000,
              value: price
            }
          end)
          |> Enum.reverse()

        Logger.info("Sending sample data directly to client: #{length(sample_data)} points")
        push_event(socket, "price_history_updated", sample_data)
      else
        socket
      end

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="w-full">
      <div
        id={@chart_id}
        class="h-96 bg-gray-800 rounded-lg"
        phx-hook="PriceChart"
        phx-update="ignore"
      >
      </div>
    </div>
    """
  end
end
