defmodule BitcoinExchangeWeb.Live.Components.TransactionListComponent do
  use BitcoinExchangeWeb, :live_component
  import BitcoinExchangeWeb.CustomComponents
  
  @doc """
  Renders a transaction list component that displays recent transactions.
  """
  
  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end
  
  def render(assigns) do
    ~H"""
    <div id={@id} class="mt-8">
      <.recent_transactions
        transactions={@transactions}
        format_currency={@format_currency}
        format_btc={@format_btc}
        format_transaction_id={@format_transaction_id}
        transaction_type_label={@transaction_type_label}
        transaction_background_color={@transaction_background_color}
      />
    </div>
    """
  end
end