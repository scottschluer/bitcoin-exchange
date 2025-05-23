defmodule BitcoinExchangeWeb.Components.Layout.Back do
  @moduledoc """
  Back navigation component.
  """
  use BitcoinExchangeWeb, :component
  alias BitcoinExchangeWeb.Components.UI.Icon

  @doc """
  Renders a back navigation link.

  ## Examples

      <.back navigate={~p"/posts"}>Back to posts</.back>
  """
  attr :navigate, :any, required: true
  slot :inner_block, required: true

  def back(assigns) do
    ~H"""
    <div class="mt-16">
      <.link
        navigate={@navigate}
        class="text-sm font-semibold leading-6 text-zinc-900 hover:text-zinc-700 dark:text-zinc-200 dark:hover:text-zinc-300"
      >
        <Icon.icon name="hero-arrow-left-solid" class="h-3 w-3" /> <%= render_slot(@inner_block) %>
      </.link>
    </div>
    """
  end
end