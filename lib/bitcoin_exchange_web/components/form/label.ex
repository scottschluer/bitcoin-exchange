defmodule BitcoinExchangeWeb.Components.Form.Label do
  @moduledoc """
  Form label component.
  """
  use BitcoinExchangeWeb, :component

  @doc """
  Renders a label for form fields.
  """
  attr :for, :string, default: nil
  slot :inner_block, required: true

  def label(assigns) do
    ~H"""
    <label for={@for} class="block text-sm font-semibold leading-6 text-zinc-800 dark:text-zinc-200">
      <%= render_slot(@inner_block) %>
    </label>
    """
  end
end