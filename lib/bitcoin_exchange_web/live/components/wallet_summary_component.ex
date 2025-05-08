defmodule BitcoinExchangeWeb.Live.Components.WalletSummaryComponent do
  use BitcoinExchangeWeb, :live_component
  import BitcoinExchangeWeb.CustomComponents
  alias BitcoinExchange.Dashboard.UIHelpers
  
  @doc """
  Renders a wallet summary component showing portfolio value and Bitcoin holdings.
  """
  
  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end
  
  def render(assigns) do
    ~H"""
    <div id={@id} class="grid grid-cols-1 sm:grid-cols-2 gap-6">
      <!-- Portfolio Value Card -->
      <div>
        <.dashboard_card title="Portfolio Value" icon_bg="bg-gray-100 dark:bg-gray-800">
          <:value>
            <span
              id="total-value"
              class={[
                "text-4xl font-bold tracking-tight text-gray-900 dark:text-white",
                UIHelpers.get_animation_class(
                  @total_value,
                  @calculate_previous_total_value.(@total_value, @bitcoin_price, @previous_price, @bitcoin_balance)
                )
              ]}
              phx-hook="AnimateValue"
            >
              {@format_currency.(@total_value)}
            </span>
          </:value>
          
          <:icon>
            <.icon name="hero-banknotes" class="h-7 w-7 text-gray-600 dark:text-gray-300" />
          </:icon>
          
          <:footer>
            <div class="grid grid-cols-2 gap-6">
              <div>
                <p class="text-sm text-gray-500 dark:text-gray-400">Cash Balance</p>
                
                <p class="mt-1 text-xl font-semibold text-gray-900 dark:text-white">
                  {@format_currency.(@cash_balance)}
                </p>
              </div>
              
              <div>
                <p class="text-sm text-gray-500 dark:text-gray-400">Bitcoin Value</p>
                
                <p class="mt-1 text-xl font-semibold text-gray-900 dark:text-white">
                  <span
                    id="bitcoin-value-display"
                    class={
                      UIHelpers.get_animation_class(
                        @bitcoin_value,
                        @calculate_previous_bitcoin_value.(@bitcoin_value, @bitcoin_price, @previous_price, @bitcoin_balance)
                      )
                    }
                    phx-hook="AnimateValue"
                  >
                    {@format_currency.(@bitcoin_value)}
                  </span>
                </p>
              </div>
            </div>
          </:footer>
        </.dashboard_card>
      </div>
      
      <!-- Bitcoin Holdings Card -->
      <div>
        <.dashboard_card
          title="Bitcoin Holdings"
          icon_bg="bg-bitcoin-orange/10 dark:bg-bitcoin-orange/20"
        >
          <:value>
            <span 
              id="bitcoin-holdings" 
              class="text-4xl font-bold tracking-tight text-gray-900 dark:text-white"
              phx-hook="AnimateValue"
            >
              {@format_btc.(@bitcoin_balance)} BTC
            </span>
          </:value>
          
          <:icon>
            <svg
              class="h-7 w-7 text-bitcoin-orange"
              viewBox="0 0 24 24"
              fill="currentColor"
              xmlns="http://www.w3.org/2000/svg"
            >
              <path d="M17.147 10.481C17.392 8.881 16.197 8.002 14.566 7.416L15.079 5.329L13.864 5.024L13.364 7.059C13.023 6.974 12.673 6.896 12.326 6.817L12.831 4.77L11.616 4.465L11.104 6.552C10.821 6.489 10.543 6.427 10.273 6.362L10.274 6.357L8.598 5.942L8.271 7.248C8.271 7.248 9.162 7.462 9.142 7.472C9.689 7.609 9.788 7.974 9.774 8.264L9.194 10.64C9.231 10.649 9.28 10.663 9.334 10.685L9.192 10.648L8.401 13.824C8.333 13.988 8.176 14.234 7.795 14.141C7.808 14.155 6.924 13.909 6.924 13.909L6.314 15.322L7.894 15.716C8.207 15.795 8.514 15.877 8.816 15.954L8.298 18.066L9.512 18.371L10.025 16.282C10.38 16.378 10.724 16.466 11.061 16.55L10.55 18.629L11.765 18.934L12.283 16.827C14.43 17.248 16.051 17.086 16.747 15.133C17.307 13.567 16.706 12.678 15.599 12.101C16.406 11.897 17.018 11.362 17.147 10.481ZM14.29 14.311C13.891 15.877 11.33 15.028 10.443 14.814L11.129 12.042C12.016 12.257 14.706 12.682 14.29 14.311ZM14.69 10.453C14.329 11.873 12.194 11.142 11.454 10.963L12.074 8.433C12.814 8.612 15.064 8.975 14.69 10.453Z" />
            </svg>
          </:icon>
          
          <:footer>
            <div>
              <p class="text-sm text-gray-500 dark:text-gray-400">Current Value</p>
              
              <p class="mt-1 text-xl font-semibold text-gray-900 dark:text-white">
                <span
                  id="current-value"
                  class={
                    UIHelpers.get_animation_class(
                      @bitcoin_value,
                      @calculate_previous_bitcoin_value.(@bitcoin_value, @bitcoin_price, @previous_price, @bitcoin_balance)
                    )
                  }
                  phx-hook="AnimateValue"
                >
                  {@format_currency.(@bitcoin_value)}
                </span>
              </p>
            </div>
          </:footer>
        </.dashboard_card>
      </div>
    </div>
    """
  end
end