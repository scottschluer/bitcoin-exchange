defmodule BitcoinExchangeWeb.CustomComponents do
  use BitcoinExchangeWeb, :component
  
  # Import specific components needed by custom components
  import BitcoinExchangeWeb.Components.UI.Icon
  import BitcoinExchangeWeb.Components.UI.ThemeToggle

  @doc """
  Renders a dashboard card with consistent styling.

  ## Examples

      <.dashboard_card
        title="Current BTC Price"
        value_class="text-4xl font-bold tracking-tight text-gray-900 dark:text-white">
        <:value>
          <span id="example-price" phx-hook="AnimateValue">
            {format_currency(@bitcoin_price)}
          </span>
        </:value>
        <:icon>
          <.icon name="hero-banknotes" class="h-6 w-6 text-gray-600 dark:text-gray-300" />
        </:icon>
        <:footer>
          <div class="grid grid-cols-2 gap-6">
            <div>
              <p class="text-sm text-gray-500 dark:text-gray-400">Cash Balance</p>
              <p class="mt-1 text-xl font-semibold text-gray-900 dark:text-white">
                {format_currency(@cash_balance)}
              </p>
            </div>
            <div>
              <p class="text-sm text-gray-500 dark:text-gray-400">Bitcoin Value</p>
              <p class="mt-1 text-xl font-semibold text-gray-900 dark:text-white">
                {format_currency(@bitcoin_value)}
              </p>
            </div>
          </div>
        </:footer>
      </.dashboard_card>
  """

  attr :title, :string, required: true, doc: "The title of the card"

  attr :value_class, :string,
    default: "text-4xl font-bold tracking-tight text-gray-900 dark:text-white",
    doc: "Custom class for value text"

  attr :icon_bg, :string,
    default: "bg-gray-100 dark:bg-gray-800",
    doc: "Background color class for the icon"

  slot :value, doc: "The main value to display"
  slot :icon, required: true, doc: "The icon to display in the card"
  slot :footer, doc: "The footer content of the card"

  def dashboard_card(assigns) do
    ~H"""
    <div class="overflow-hidden rounded-xl border border-gray-200 bg-white shadow-sm dark:border-gray-700 dark:bg-bitcoin-gray">
      <div class="p-6">
        <div class="flex items-start justify-between">
          <div>
            <h2 class="text-sm font-bold text-gray-500 dark:text-gray-400">
              {@title}
            </h2>
            
            <div class="mt-4 flex items-baseline">
              <p class={@value_class}>
                {render_slot(@value)}
              </p>
            </div>
          </div>
          
          <div class={"rounded-full #{@icon_bg} p-3 relative -top-3"}>
            {render_slot(@icon)}
          </div>
        </div>
        
        <%= if @footer do %>
          <div class="mt-6">
            {render_slot(@footer)}
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  def price_chart(assigns) do
    ~H"""
    <div class="overflow-hidden rounded-xl border border-gray-200 bg-white shadow-sm dark:border-gray-700 dark:bg-bitcoin-gray">
      <div class="p-6">
        <div class="flex items-center justify-between mb-6">
          <h2 class="text-lg font-medium text-gray-900 dark:text-white">
            Bitcoin Price Chart (Mock Data)
          </h2>
        </div>
        
    <!-- Bitcoin price chart -->
        <div class="h-96 bg-gray-800 rounded-lg flex items-center justify-center">
          <canvas id="price-chart" class="w-full h-full" phx-hook="PriceChart" phx-update="ignore">
          </canvas>
        </div>
        
        <div class="mt-6 grid grid-cols-2 gap-6 sm:grid-cols-4">
          <div>
            <p class="text-sm text-gray-500 dark:text-gray-400">Current Price</p>
            
            <p class="mt-1 text-lg font-semibold text-gray-900 dark:text-white">
              <span id="chart-bitcoin-price" phx-hook="AnimateValue">
                {@bitcoin_price_formatted}
              </span>
            </p>
          </div>
          
          <div>
            <p class="text-sm text-gray-500 dark:text-gray-400">1D Change</p>
            
            <p class={[
              "mt-1 text-lg font-semibold flex items-center",
              (decimal_gte?(@price_change_24h, 0) && "text-green-600 dark:text-green-400") ||
                "text-red-600 dark:text-red-400"
            ]}>
              <%= if decimal_gte?(@price_change_24h, 0) do %>
                <.icon name="hero-arrow-up" class="mr-1 h-4 w-4" />
                <span id="chart-price-change" phx-hook="AnimateValue">
                  {format_percentage(@price_change_24h)}
                </span>
              <% else %>
                <.icon name="hero-arrow-down" class="mr-1 h-4 w-4" />
                <span id="chart-price-change" phx-hook="AnimateValue">
                  {format_percentage(@price_change_24h)}
                </span>
              <% end %>
            </p>
          </div>
          
          <div>
            <p class="text-sm text-gray-500 dark:text-gray-400">24h Volume</p>
            
            <p class="mt-1 text-lg font-semibold text-gray-900 dark:text-white">
              <span id="volume-24h-display" phx-hook="AnimateValue">
                {format_volume(@volume_24h)}
              </span>
            </p>
          </div>
          
          <div>
            <p class="text-sm text-gray-500 dark:text-gray-400">Market Cap</p>
            
            <p class="mt-1 text-lg font-semibold text-gray-900 dark:text-white">
              <span id="market-cap-display" phx-hook="AnimateValue">
                {format_market_cap(@market_cap)}
              </span>
            </p>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def dashboard_header(assigns) do
    ~H"""
    <div class="flex h-16 items-center justify-between px-6 lg:px-8">
      <div class="flex items-center gap-4">
        <div class="text-bitcoin-orange font-bold text-2xl flex items-center">
          <div class="flex items-center space-x-2">
            <svg class="h-8 w-8" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
              <path
                d="M12 24C18.6274 24 24 18.6274 24 12C24 5.37258 18.6274 0 12 0C5.37258 0 0 5.37258 0 12C0 18.6274 5.37258 24 12 24Z"
                fill="#F7931A"
              />
              <path
                d="M17.147 10.481C17.392 8.881 16.197 8.002 14.566 7.416L15.079 5.329L13.864 5.024L13.364 7.059C13.023 6.974 12.673 6.896 12.326 6.817L12.831 4.77L11.616 4.465L11.104 6.552C10.821 6.489 10.543 6.427 10.273 6.362L10.274 6.357L8.598 5.942L8.271 7.248C8.271 7.248 9.162 7.462 9.142 7.472C9.689 7.609 9.788 7.974 9.774 8.264L9.194 10.64C9.231 10.649 9.28 10.663 9.334 10.685L9.192 10.648L8.401 13.824C8.333 13.988 8.176 14.234 7.795 14.141C7.808 14.155 6.924 13.909 6.924 13.909L6.314 15.322L7.894 15.716C8.207 15.795 8.514 15.877 8.816 15.954L8.298 18.066L9.512 18.371L10.025 16.282C10.38 16.378 10.724 16.466 11.061 16.55L10.55 18.629L11.765 18.934L12.283 16.827C14.43 17.248 16.051 17.086 16.747 15.133C17.307 13.567 16.706 12.678 15.599 12.101C16.406 11.897 17.018 11.362 17.147 10.481ZM14.29 14.311C13.891 15.877 11.33 15.028 10.443 14.814L11.129 12.042C12.016 12.257 14.706 12.682 14.29 14.311ZM14.69 10.453C14.329 11.873 12.194 11.142 11.454 10.963L12.074 8.433C12.814 8.612 15.064 8.975 14.69 10.453Z"
                fill="white"
              />
            </svg>
             <span class="text-2xl">Bitcoin Exchange</span>
          </div>
        </div>
      </div>
      
      <div class="flex items-center gap-6">
        <.theme_toggle />
      </div>
    </div>
    """
  end

  def dashboard_footer(assigns) do
    ~H"""
    <div class="px-2 py-6 lg:px-8">
      <div class="flex flex-col md:flex-row items-center justify-between gap-4">
        <div class="text-sm text-gray-500 dark:text-gray-400">
          © {DateTime.utc_now().year} Bitcoin Exchange. For demonstration purposes only.
        </div>
        
        <div class="text-sm text-gray-500 dark:text-gray-400">
          Prices are for mock data purposes only and do not reflect real market values.
        </div>
      </div>
    </div>
    """
  end

  # Format large numbers to display in abbreviated form (B for billions, T for trillions)
  defp format_volume(volume) when is_struct(volume, Decimal) do
    # Convert Decimal to number first
    decimal_float = Decimal.to_float(volume)
    format_volume(decimal_float)
  end

  defp format_volume(volume) when is_number(volume) do
    cond do
      volume >= 1_000_000_000_000 ->
        "$#{:erlang.float_to_binary(volume / 1_000_000_000_000, decimals: 2)}T"

      volume >= 1_000_000_000 ->
        "$#{:erlang.float_to_binary(volume / 1_000_000_000, decimals: 2)}B"

      volume >= 1_000_000 ->
        "$#{:erlang.float_to_binary(volume / 1_000_000, decimals: 2)}M"

      true ->
        "$#{:erlang.float_to_binary(volume / 1_000, decimals: 2)}K"
    end
  end

  defp format_volume(_), do: "$0.00B"

  defp format_market_cap(market_cap) when is_struct(market_cap, Decimal) do
    # Convert Decimal to number first
    decimal_float = Decimal.to_float(market_cap)
    format_market_cap(decimal_float)
  end

  defp format_market_cap(market_cap) when is_number(market_cap) do
    cond do
      market_cap >= 1_000_000_000_000 ->
        "$#{:erlang.float_to_binary(market_cap / 1_000_000_000_000, decimals: 2)}T"

      market_cap >= 1_000_000_000 ->
        "$#{:erlang.float_to_binary(market_cap / 1_000_000_000, decimals: 2)}B"

      market_cap >= 1_000_000 ->
        "$#{:erlang.float_to_binary(market_cap / 1_000_000, decimals: 2)}M"

      true ->
        "$#{:erlang.float_to_binary(market_cap / 1_000, decimals: 2)}K"
    end
  end

  defp format_market_cap(_), do: "$0.00B"

  @doc """
  Formats a percentage value with 1 decimal point precision.
  Adds a "+" sign for positive values.

  ## Examples

      iex> format_percentage(5.6789)
      "+5.7%"

      iex> format_percentage(-2.345)
      "-2.3%"
  """
  def format_percentage(percentage) when is_struct(percentage, Decimal) do
    # Handle Decimal type
    formatted = Decimal.abs(percentage) |> Decimal.round(2) |> Decimal.to_string()

    # Add sign prefix (+ or -)
    if Decimal.compare(percentage, Decimal.new(0)) != :lt do
      "+#{formatted}%"
    else
      "-#{formatted}%"
    end
  end

  def format_percentage(percentage) when is_number(percentage) do
    # Format to 2 decimal places
    formatted = :erlang.float_to_binary(abs(percentage), decimals: 2)

    # Add sign prefix (+ or -)
    if percentage >= 0 do
      "+#{formatted}%"
    else
      "-#{formatted}%"
    end
  end

  def format_percentage(_), do: "0.00%"

  # Helper functions to handle Decimal types
  defp decimal_gte?(a, b) when is_struct(a, Decimal) do
    Decimal.compare(a, Decimal.new(b)) in [:gt, :eq]
  end

  defp decimal_gte?(a, b) when is_number(a) do
    a >= b
  end

  defp decimal_gte?(_, _), do: false

  def recent_transactions(assigns) do
    assigns = assign_new(assigns, :format_transaction_id, fn -> fn id -> id end end)

    ~H"""
    <div class="overflow-hidden rounded-xl border border-gray-200 bg-white shadow-sm dark:border-gray-700 dark:bg-bitcoin-gray">
      <div class="px-6 py-5 border-b border-gray-200 dark:border-gray-700">
        <h2 class="text-lg font-medium text-gray-900 dark:text-white">Recent Transactions</h2>
      </div>
      
      <div class="overflow-x-auto">
        <table class="min-w-full divide-y divide-gray-200 dark:divide-gray-700">
          <thead class="bg-gray-50 dark:bg-gray-800/50">
            <tr>
              <th
                scope="col"
                class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider"
              >
                Type
              </th>
              
              <th
                scope="col"
                class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider"
              >
                Transaction ID
              </th>
              
              <th
                scope="col"
                class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider"
              >
                Amount
              </th>
              
              <th
                scope="col"
                class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider"
              >
                Price
              </th>
              
              <th
                scope="col"
                class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider"
              >
                Total USD
              </th>
              
              <th
                scope="col"
                class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider"
              >
                Date & Time
              </th>
            </tr>
          </thead>
          
          <tbody class="bg-white divide-y divide-gray-200 dark:bg-bitcoin-gray dark:divide-gray-700">
            <%= for transaction <- @transactions do %>
              <tr class="hover:bg-gray-50 dark:hover:bg-gray-800/50 transition-colors duration-150">
                <td class="px-6 py-4 whitespace-nowrap">
                  <div class="flex items-center">
                    <div class={[
                      "flex-shrink-0 h-8 w-8 rounded-full flex items-center justify-center",
                      @transaction_background_color.(transaction.type)
                    ]}>
                      <%= if transaction.type == "buy" do %>
                        <.icon
                          name="hero-arrow-down-circle"
                          class="h-5 w-5 text-green-600 dark:text-green-400"
                        />
                      <% else %>
                        <%= if transaction.type == "sell" do %>
                          <.icon
                            name="hero-arrow-up-circle"
                            class="h-5 w-5 text-red-600 dark:text-red-400"
                          />
                        <% else %>
                          <.icon
                            name="hero-banknotes"
                            class="h-5 w-5 text-blue-600 dark:text-blue-400"
                          />
                        <% end %>
                      <% end %>
                    </div>
                    
                    <div class="ml-4">
                      <div class="text-sm font-medium text-gray-900 dark:text-white">
                        {@transaction_type_label.(transaction.type)}
                      </div>
                    </div>
                  </div>
                </td>
                
                <td class="px-6 py-4 whitespace-nowrap">
                  <div class="text-sm font-mono text-gray-900 dark:text-white" title={transaction.id}>
                    {@format_transaction_id.(transaction.id)}
                  </div>
                </td>
                
                <td class="px-6 py-4 whitespace-nowrap">
                  <div class="text-sm text-gray-900 dark:text-white">
                    <%= if transaction.type == "add_funds" do %>
                      {@format_currency.(transaction.amount)}
                    <% else %>
                      {@format_btc.(transaction.amount)} BTC
                    <% end %>
                  </div>
                </td>
                
                <td class="px-6 py-4 whitespace-nowrap">
                  <div class="text-sm text-gray-900 dark:text-white">
                    <%= if transaction.type == "buy" || transaction.type == "sell" do %>
                      {@format_currency.(transaction.price)}
                    <% else %>
                      —
                    <% end %>
                  </div>
                </td>
                
                <td class="px-6 py-4 whitespace-nowrap">
                  <div class="text-sm text-gray-900 dark:text-white">
                    <%= if transaction.type == "buy" || transaction.type == "sell" do %>
                      {@format_currency.(transaction.price * transaction.amount)}
                    <% else %>
                      —
                    <% end %>
                  </div>
                </td>
                
                <td class="px-6 py-4 whitespace-nowrap">
                  <div class="text-sm text-gray-900 dark:text-white">
                    {Calendar.strftime(transaction.timestamp, "%b %d, %Y %H:%M:%S")}
                  </div>
                </td>
              </tr>
            <% end %>
          </tbody>
        </table>
      </div>
    </div>
    """
  end
end
