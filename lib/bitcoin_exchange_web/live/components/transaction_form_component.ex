defmodule BitcoinExchangeWeb.Live.Components.TransactionFormComponent do
  use BitcoinExchangeWeb, :live_component
  require Logger

  @doc """
  Renders a transaction form component for add funds, buy bitcoin, and sell bitcoin operations.
  """

  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end

  def render(assigns) do
    ~H"""
    <div id={@id}>
      <%= if @modal_form do %>
        <.modal id="transaction-modal" show={true} on_cancel={JS.push("close_modal")}>
          <:title>
            <%= case @modal_form do %>
              <% :add_funds -> %>
                Add Funds to Your Account
              <% :buy_bitcoin -> %>
                Buy Bitcoin
              <% :sell_bitcoin -> %>
                Sell Bitcoin
            <% end %>
          </:title>
          
          <%= case @modal_form do %>
            <% :add_funds -> %>
              <%= if @form_error do %>
                <div class="mb-4 rounded-md bg-red-50 p-4 dark:bg-red-900/30">
                  <div class="flex">
                    <div class="flex-shrink-0">
                      <.icon
                        name="hero-exclamation-circle"
                        class="h-5 w-5 text-red-400 dark:text-red-300"
                      />
                    </div>
                    
                    <div class="ml-3">
                      <p class="text-sm text-red-700 dark:text-red-200">{@form_error}</p>
                    </div>
                  </div>
                </div>
              <% end %>
              
              <div class="mb-4 text-sm text-zinc-700 dark:text-zinc-300">
                <p>
                  Current Balance:
                  <span class="font-semibold text-zinc-900 dark:text-white">
                    {@format_currency.(@cash_balance)}
                  </span>
                </p>
              </div>
              
              <.simple_form for={%{}} phx-submit="add_funds_submit">
                <.input
                  name="amount"
                  label="Amount ($)"
                  type="number"
                  step="0.01"
                  min="0.01"
                  value=""
                  required
                />
                <:actions>
                  <.button
                    type="submit"
                    class="w-full bg-bitcoin-primary hover:bg-bitcoin-primary/90"
                    phx-disable-with="Adding funds..."
                  >
                    Add Funds
                  </.button>
                </:actions>
              </.simple_form>
            <% :buy_bitcoin -> %>
              <div class="mb-4 text-sm text-zinc-700 dark:text-zinc-300">
                <p>
                  Current Price:
                  <span class="font-semibold text-zinc-900 dark:text-white">
                    {@format_currency.(@bitcoin_price)} / BTC
                  </span>
                </p>
                
                <p>
                  Available Cash:
                  <span class="font-semibold text-zinc-900 dark:text-white">
                    {@format_currency.(@cash_balance)}
                  </span>
                </p>
              </div>
              
              <%= if @form_error do %>
                <div class="mb-4 rounded-md bg-red-50 p-4 dark:bg-red-900/30">
                  <div class="flex">
                    <div class="flex-shrink-0">
                      <.icon
                        name="hero-exclamation-circle"
                        class="h-5 w-5 text-red-400 dark:text-red-300"
                      />
                    </div>
                    
                    <div class="ml-3">
                      <p class="text-sm text-red-700 dark:text-red-200">{@form_error}</p>
                    </div>
                  </div>
                </div>
              <% end %>
              
              <.simple_form for={%{}} phx-submit="buy_bitcoin_submit">
                <div>
                  <.input
                    name="amount"
                    label="USD Amount to Spend"
                    type="number"
                    step="0.00000001"
                    min="0.01"
                    max={@cash_balance}
                    placeholder="Enter USD amount"
                    value=""
                    required
                    id="buy-amount-input"
                  />
                  <div class="mt-2 flex justify-end">
                    <button
                      type="button"
                      phx-click="set_buy_max"
                      class="px-3 py-1.5 text-sm bg-gray-100 dark:bg-gray-800 text-bitcoin-primary dark:text-bitcoin-orange hover:bg-gray-200 dark:hover:bg-gray-700 rounded-md font-medium"
                    >
                      Buy Max
                    </button>
                  </div>
                </div>
                
                <div class="mt-2 text-sm text-gray-600 dark:text-gray-300">
                  You will receive approximately
                  <span
                    id="btc-estimate"
                    class="font-semibold text-bitcoin-primary dark:text-bitcoin-orange"
                    phx-hook="CalculateBtcAmount"
                    data-btc-price={
                      if is_struct(@bitcoin_price, Decimal),
                        do: Decimal.to_string(@bitcoin_price),
                        else: @bitcoin_price
                    }
                  >
                    0.00000000 BTC
                  </span>
                </div>
                
                <:actions>
                  <.button
                    type="submit"
                    class="w-full bg-bitcoin-primary hover:bg-bitcoin-primary/90"
                    phx-disable-with="Buying Bitcoin..."
                  >
                    Buy Bitcoin
                  </.button>
                </:actions>
              </.simple_form>
            <% :sell_bitcoin -> %>
              <div class="mb-4 text-sm text-zinc-700 dark:text-zinc-300">
                <p>
                  Current Price:
                  <span class="font-semibold text-zinc-900 dark:text-white">
                    {@format_currency.(@bitcoin_price)} / BTC
                  </span>
                </p>
                
                <p>
                  Available Bitcoin:
                  <span class="font-semibold text-zinc-900 dark:text-white">
                    {@format_btc.(@bitcoin_balance)} BTC
                  </span>
                </p>
              </div>
              
              <%= if @form_error do %>
                <div class="mb-4 rounded-md bg-red-50 p-4 dark:bg-red-900/30">
                  <div class="flex">
                    <div class="flex-shrink-0">
                      <.icon
                        name="hero-exclamation-circle"
                        class="h-5 w-5 text-red-400 dark:text-red-300"
                      />
                    </div>
                    
                    <div class="ml-3">
                      <p class="text-sm text-red-700 dark:text-red-200">{@form_error}</p>
                    </div>
                  </div>
                </div>
              <% end %>
              
              <.simple_form for={%{}} phx-submit="sell_bitcoin_submit">
                <div>
                  <.input
                    name="amount"
                    label="BTC Amount to Sell"
                    type="number"
                    step="0.00000001"
                    min="0.00000001"
                    max={@bitcoin_balance}
                    placeholder="Enter BTC amount"
                    value=""
                    required
                    id="sell-amount-input"
                  />
                  <div class="mt-2 flex justify-end">
                    <button
                      type="button"
                      phx-click="set_sell_max"
                      class="px-3 py-1.5 text-sm bg-gray-100 dark:bg-gray-800 text-bitcoin-primary dark:text-bitcoin-orange hover:bg-gray-200 dark:hover:bg-gray-700 rounded-md font-medium"
                    >
                      Sell Max
                    </button>
                  </div>
                </div>
                
                <div class="mt-2 text-sm text-gray-600 dark:text-gray-300">
                  You will receive approximately
                  <span
                    id="usd-estimate"
                    class="font-semibold text-bitcoin-primary dark:text-bitcoin-orange"
                    phx-hook="CalculateUsdAmount"
                    data-btc-price={
                      if is_struct(@bitcoin_price, Decimal),
                        do: Decimal.to_string(@bitcoin_price),
                        else: @bitcoin_price
                    }
                  >
                    $0.00
                  </span>
                </div>
                
                <:actions>
                  <.button
                    type="submit"
                    class="w-full bg-bitcoin-primary hover:bg-bitcoin-primary/90"
                    phx-disable-with="Selling Bitcoin..."
                  >
                    Sell Bitcoin
                  </.button>
                </:actions>
              </.simple_form>
          <% end %>
        </.modal>
      <% end %>
    </div>
    """
  end
end
