defmodule BitcoinExchangeWeb.Live.Components.PriceDisplayComponent do
  use BitcoinExchangeWeb, :live_component
  import BitcoinExchangeWeb.CustomComponents
  alias BitcoinExchange.Dashboard.UIHelpers

  @doc """
  Renders a Bitcoin price display component with price, change percentages, and styling.
  """

  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end

  def render(assigns) do
    ~H"""
    <div id={@id}>
      <.dashboard_card
        title="Current BTC Price"
        value_class={
          "text-4xl font-bold tracking-tight #{if @bitcoin_price > @previous_price, do: "text-green-600 dark:text-green-400", else: "text-red-600 dark:text-red-400"}"
        }
        icon_bg="bg-green-100 dark:bg-green-900/30"
      >
        <:value>
          <span
            id="bitcoin-price"
            class={UIHelpers.get_animation_class(@bitcoin_price, @previous_price)}
            phx-hook="AnimateValue"
          >
            {@format_currency.(@bitcoin_price)}
          </span>
        </:value>
        
        <:icon>
          <.icon name="hero-currency-dollar" class="h-7 w-7 text-green-600 dark:text-green-400" />
        </:icon>
        
        <:footer>
          <div class="grid grid-cols-3 gap-6">
            <div>
              <p class="text-sm text-gray-500 dark:text-gray-400">1H Change</p>
              
              <div class={[
                "mt-1 inline-flex items-center rounded-full px-2.5 py-1 text-sm font-medium",
                if @decimal_gte?.(@price_change_1h || Decimal.new(0), 0) do
                  "bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-300"
                else
                  "bg-red-100 text-red-800 dark:bg-red-900/30 dark:text-red-300"
                end
              ]}>
                <%= if @decimal_gte?.(@price_change_1h || Decimal.new(0), 0) do %>
                  <.icon name="hero-arrow-up" class="mr-1 h-3 w-3" />
                <% else %>
                  <.icon name="hero-arrow-down" class="mr-1 h-3 w-3" />
                <% end %>
                
                <span id="price-change-1h">
                  {@format_decimal_percentage.(@price_change_1h || Decimal.new(0))}
                </span>
              </div>
            </div>
            
            <div>
              <p class="text-sm text-gray-500 dark:text-gray-400">1D Change</p>
              
              <div class={[
                "mt-1 inline-flex items-center rounded-full px-2.5 py-1 text-sm font-medium",
                if @decimal_gte?.(@price_change_24h, 0) do
                  "bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-300"
                else
                  "bg-red-100 text-red-800 dark:bg-red-900/30 dark:text-red-300"
                end
              ]}>
                <%= if @decimal_gte?.(@price_change_24h, 0) do %>
                  <.icon name="hero-arrow-up" class="mr-1 h-3 w-3" />
                <% else %>
                  <.icon name="hero-arrow-down" class="mr-1 h-3 w-3" />
                <% end %>
                
                <span id="price-change-24h">
                  {@format_decimal_percentage.(@price_change_24h)}
                </span>
              </div>
            </div>
            
            <div>
              <p class="text-sm text-gray-500 dark:text-gray-400">7D Change</p>
              
              <div class={[
                "mt-1 inline-flex items-center rounded-full px-2.5 py-1 text-sm font-medium",
                if @decimal_gte?.(@price_change_7d, 0) do
                  "bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-300"
                else
                  "bg-red-100 text-red-800 dark:bg-red-900/30 dark:text-red-300"
                end
              ]}>
                <%= if @decimal_gte?.(@price_change_7d, 0) do %>
                  <.icon name="hero-arrow-up" class="mr-1 h-3 w-3" />
                <% else %>
                  <.icon name="hero-arrow-down" class="mr-1 h-3 w-3" />
                <% end %>
                
                <span id="price-change-7d">
                  {@format_decimal_percentage.(@price_change_7d)}
                </span>
              </div>
            </div>
          </div>
        </:footer>
      </.dashboard_card>
    </div>
    """
  end
end
