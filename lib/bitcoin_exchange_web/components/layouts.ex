defmodule BitcoinExchangeWeb.Layouts do
  @moduledoc """
  This module holds different layouts used by your application.

  See the `layouts` directory for all templates available.
  The "root" layout is a skeleton rendered as part of the
  application router. The "app" layout is set as the default
  layout on both `use BitcoinExchangeWeb, :controller` and
  `use BitcoinExchangeWeb, :live_view`.
  """
  use BitcoinExchangeWeb, :html

  embed_templates "layouts/*"

  def dashboard(assigns) do
    ~H"""
    <div class="flex min-h-screen flex-col bg-gray-50 dark:bg-bitcoin-black">
      <header class="sticky top-0 z-50 border-b border-gray-200 bg-white shadow-sm dark:border-gray-700 dark:bg-bitcoin-gray">
        {render_slot(@header)}
      </header>
      
      <main class="flex-1 pb-10">
        {render_slot(@inner_block)}
      </main>
      
      <footer class="border-t border-gray-200 bg-white dark:border-gray-700 dark:bg-bitcoin-gray">
        {render_slot(@footer)}
      </footer>
    </div>
    """
  end
end
