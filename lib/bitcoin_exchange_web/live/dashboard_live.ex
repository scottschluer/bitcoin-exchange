defmodule BitcoinExchangeWeb.DashboardLive do
  use BitcoinExchangeWeb, :live_view
  alias BitcoinExchangeWeb.Layouts
  import BitcoinExchangeWeb.CustomComponents
  import BitcoinExchangeWeb.LiveHelpers
  
  # Service modules
  alias BitcoinExchange.Dashboard.DashboardService
  alias BitcoinExchange.Dashboard.TransactionService
  alias BitcoinExchange.Dashboard.UIHelpers
  
  # UI Components
  alias BitcoinExchangeWeb.Live.Components.PriceDisplayComponent
  alias BitcoinExchangeWeb.Live.Components.WalletSummaryComponent
  alias BitcoinExchangeWeb.Live.Components.TransactionFormComponent
  alias BitcoinExchangeWeb.Live.Components.TransactionListComponent

  @doc """
  Mount the LiveView and initialize the dashboard data.
  """
  def mount(_params, _session, socket) do
    # Initialize dashboard data using the service
    initial_data = DashboardService.initialize_dashboard()
    
    {:ok, assign(socket, initial_data)}
  end

  # Handle price updates from PubSub
  def handle_info({:price_updated, price_data}, socket) do
    # Process price update using the service
    updated_assigns = DashboardService.process_price_update(socket.assigns, price_data)
    
    {:noreply, update_socket_assigns(socket, updated_assigns)}
  end

  # Handle wallet updates from PubSub (legacy format)
  def handle_info({:wallet_updated, wallet}, socket) do
    # Process wallet update using the service
    updated_assigns = DashboardService.process_wallet_update(socket.assigns, wallet)
    
    {:noreply, update_socket_assigns(socket, updated_assigns)}
  end

  # Handle wallet updates with transactions from PubSub (new format)
  def handle_info({:wallet_updated, wallet, transactions}, socket) do
    # Process wallet update with transactions using the service
    updated_assigns = DashboardService.process_wallet_update(socket.assigns, wallet, transactions)
    
    {:noreply, update_socket_assigns(socket, updated_assigns)}
  end

  # Open the Add Funds modal
  def handle_event("add_funds_click", _params, socket) do
    {:noreply, open_modal_form(socket, :add_funds)}
  end

  # Open the Buy Bitcoin modal
  def handle_event("buy_bitcoin_click", _params, socket) do
    {:noreply, open_modal_form(socket, :buy_bitcoin)}
  end

  # Open the Sell Bitcoin modal
  def handle_event("sell_bitcoin_click", _params, socket) do
    {:noreply, open_modal_form(socket, :sell_bitcoin)}
  end

  # Close any open modal
  def handle_event("close_modal", _params, socket) do
    {:noreply, clear_form_and_error(socket)}
  end

  # Set the Buy Bitcoin input to the maximum available amount
  def handle_event("set_buy_max", _params, socket) do
    # Round the cash balance to 2 decimal places for consistency
    rounded_balance = Float.round(socket.assigns.cash_balance, 2)

    # Format with exactly 2 decimal places
    max_cash_value = :erlang.float_to_binary(rounded_balance, decimals: 2)

    # Set the input value
    {:noreply, push_input_value(socket, "buy-amount-input", max_cash_value)}
  end

  # Set the Sell Bitcoin input to the maximum available amount
  def handle_event("set_sell_max", _params, socket) do
    # Round the bitcoin balance to 8 decimal places for consistency
    rounded_btc_balance = Float.round(socket.assigns.bitcoin_balance, 8)

    # Format the bitcoin balance to 8 decimal places
    max_btc_value = :erlang.float_to_binary(rounded_btc_balance, decimals: 8)

    # Set the input value
    {:noreply, push_input_value(socket, "sell-amount-input", max_btc_value)}
  end

  # Handle the Add Funds form submission
  def handle_event("add_funds_submit", %{"amount" => amount_str}, socket) do
    # Process the add funds request using the service
    case DashboardService.add_funds(socket.assigns, amount_str) do
      {:ok, updated_assigns} ->
        {:noreply, update_socket_assigns(socket, updated_assigns)}
        
      {:error, error_message} ->
        {:noreply, show_form_error(socket, error_message)}
    end
  end

  # Handle the Buy Bitcoin form submission
  def handle_event("buy_bitcoin_submit", %{"amount" => amount_str}, socket) do
    # Process the buy transaction using the transaction service
    case TransactionService.handle_transaction(:buy, amount_str, socket.assigns) do
      {:ok, updated_assigns} ->
        {:noreply, update_socket_assigns(socket, updated_assigns)}
        
      {:error, error_message} ->
        {:noreply, show_form_error(socket, error_message)}
    end
  end
  
  # Handle the Sell Bitcoin form submission
  def handle_event("sell_bitcoin_submit", %{"amount" => amount_str}, socket) do
    # Process the sell transaction using the transaction service
    case TransactionService.handle_transaction(:sell, amount_str, socket.assigns) do
      {:ok, updated_assigns} ->
        {:noreply, update_socket_assigns(socket, updated_assigns)}
        
      {:error, error_message} ->
        {:noreply, show_form_error(socket, error_message)}
    end
  end

  @doc """
  Render the dashboard LiveView
  """
  def render(assigns) do
    # Round cash balance to 2 decimal places for display and validation
    assigns = update(assigns, :cash_balance, &Float.round(&1, 2))

    # Create function reference assigns for passing to components
    assigns =
      assign(
        assigns,
        format_currency: &UIHelpers.format_currency/1,
        format_btc: &UIHelpers.format_btc/1,
        format_decimal_percentage: &UIHelpers.format_decimal_percentage/1,
        format_transaction_id: &UIHelpers.format_transaction_id/1,
        transaction_type_label: &UIHelpers.transaction_type_label/1,
        transaction_background_color: &UIHelpers.transaction_background_color/1,
        calculate_previous_total_value: &UIHelpers.calculate_previous_total_value/4,
        calculate_previous_bitcoin_value: &UIHelpers.calculate_previous_bitcoin_value/4,
        decimal_gte?: &BitcoinExchange.Utils.DecimalUtils.gte?/2
      )

    ~H"""
    <Layouts.dashboard>
      <:header>
        <.dashboard_header />
      </:header>
      
    <!-- Main dashboard content -->
      <div class="bg-gradient-to-b from-bitcoin-orange/10 to-transparent dark:from-bitcoin-orange/5 pt-8 pb-6">
        <div class="px-6 lg:px-8">
          <!-- Spacer div for proper spacing -->
          <div class="h-4"></div>
        </div>
      </div>
      
    <!-- Stats overview section -->
      <div
        class="mx-auto max-w-7xl px-6 lg:px-8 -mt-8"
        id="dashboard-content"
        phx-hook="InputValueSetter"
      >
        <!-- Cards Section -->
        <div class="grid grid-cols-3 gap-6">
          <!-- Price Display Component -->
          <div class="col-span-3 lg:col-span-1">
            <.live_component
              module={PriceDisplayComponent}
              id="price-display"
              bitcoin_price={@bitcoin_price}
              previous_price={@previous_price}
              price_change_1h={@price_change_1h}
              price_change_24h={@price_change_24h}
              price_change_7d={@price_change_7d}
              format_currency={@format_currency}
              format_decimal_percentage={@format_decimal_percentage}
              decimal_gte?={@decimal_gte?}
            />
          </div>
          
    <!-- Wallet Summary Component - Spans 2 columns -->
          <div class="col-span-3 lg:col-span-2">
            <.live_component
              module={WalletSummaryComponent}
              id="wallet-summary"
              cash_balance={@cash_balance}
              bitcoin_balance={@bitcoin_balance}
              bitcoin_price={@bitcoin_price}
              previous_price={@previous_price}
              bitcoin_value={@bitcoin_value}
              total_value={@total_value}
              format_currency={@format_currency}
              format_btc={@format_btc}
              calculate_previous_total_value={@calculate_previous_total_value}
              calculate_previous_bitcoin_value={@calculate_previous_bitcoin_value}
            />
          </div>
        </div>
        
    <!-- Action Buttons Section - Ensure exact alignment with cards -->
        <div class="mt-6 grid grid-cols-3 gap-6">
          <!-- Add Funds Button -->
          <div class="col-span-3 lg:col-span-1">
            <button
              type="button"
              phx-click="add_funds_click"
              class="w-full inline-flex items-center justify-center rounded-lg bg-white px-4 py-3 text-sm font-medium text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 hover:bg-gray-50 dark:bg-bitcoin-gray dark:text-white dark:ring-gray-700 dark:hover:bg-gray-800"
            >
              <.icon name="hero-plus-circle" class="mr-2 h-5 w-5 text-gray-400 dark:text-gray-300" />
              Add Funds
            </button>
          </div>
          
    <!-- Buy Bitcoin Button -->
          <div class="col-span-3 lg:col-span-1">
            <button
              type="button"
              phx-click="buy_bitcoin_click"
              class="w-full inline-flex items-center justify-center rounded-lg bg-bitcoin-orange px-4 py-3 text-sm font-medium text-white shadow-sm hover:bg-amber-600 focus:outline-none focus:ring-2 focus:ring-bitcoin-orange/50 focus:ring-offset-2 dark:hover:bg-amber-600"
            >
              <.icon name="hero-arrow-down-circle" class="mr-2 h-5 w-5" /> Buy Bitcoin
            </button>
          </div>
          
    <!-- Sell Bitcoin Button -->
          <div class="col-span-3 lg:col-span-1">
            <button
              type="button"
              phx-click="sell_bitcoin_click"
              class="w-full inline-flex items-center justify-center rounded-lg bg-white px-4 py-3 text-sm font-medium text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 hover:bg-gray-50 dark:bg-bitcoin-gray dark:text-white dark:ring-gray-700 dark:hover:bg-gray-800"
            >
              <.icon
                name="hero-arrow-up-circle"
                class="mr-2 h-5 w-5 text-gray-400 dark:text-gray-300"
              /> Sell Bitcoin
            </button>
          </div>
        </div>
        
    <!-- Transaction Form Component -->
        <.live_component
          module={TransactionFormComponent}
          id="transaction-form"
          bitcoin_price={@bitcoin_price}
          cash_balance={@cash_balance}
          bitcoin_balance={@bitcoin_balance}
          modal_form={@modal_form}
          form_error={@form_error}
          format_currency={@format_currency}
          format_btc={@format_btc}
        />
        
    <!-- Price Chart Section -->
        <div class="mt-8">
          <.price_chart
            bitcoin_price={@bitcoin_price}
            bitcoin_price_formatted={@format_currency.(@bitcoin_price)}
            previous_price={@previous_price}
            price_change_24h={@price_change_24h}
            volume_24h={@volume_24h}
            market_cap={@market_cap}
          />
        </div>
        
    <!-- Transactions List Component -->
        <.live_component
          module={TransactionListComponent}
          id="transaction-list"
          transactions={@transactions}
          format_currency={@format_currency}
          format_btc={@format_btc}
          format_transaction_id={@format_transaction_id}
          transaction_type_label={@transaction_type_label}
          transaction_background_color={@transaction_background_color}
        />
      </div>
      
      <:footer>
        <.dashboard_footer />
      </:footer>
    </Layouts.dashboard>
    """
  end
end