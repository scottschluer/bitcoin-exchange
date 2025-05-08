defmodule BitcoinExchangeWeb.Components.Feedback.Error do
  @moduledoc """
  Component for displaying error messages.
  """
  use BitcoinExchangeWeb, :component
  alias BitcoinExchangeWeb.Components.UI.Icon

  @doc """
  Generates a generic error message.
  """
  slot :inner_block, required: true

  def error(assigns) do
    ~H"""
    <p class="mt-3 flex gap-3 text-sm leading-6 text-rose-600 dark:text-rose-400">
      <Icon.icon name="hero-exclamation-circle-mini" class="mt-0.5 h-5 w-5 flex-none" /> 
      <%= render_slot(@inner_block) %>
    </p>
    """
  end
end