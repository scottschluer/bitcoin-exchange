defmodule BitcoinExchangeWeb.Components.Layout.Card do
  @moduledoc """
  Card component.
  """
  use BitcoinExchangeWeb, :component

  @doc """
  Renders a card component.
  """
  attr :class, :string, default: nil
  attr :id, :string, default: nil
  slot :header
  slot :inner_block, required: true

  def card(assigns) do
    ~H"""
    <div
      id={@id}
      class={[
        "bg-white dark:bg-bitcoin-gray rounded-lg shadow-sm border border-gray-200 dark:border-gray-700 overflow-hidden",
        @class
      ]}
    >
      <%= if @header != [] do %>
        <div class="border-b border-gray-200 dark:border-gray-700 px-6 py-4">
          <%= render_slot(@header) %>
        </div>
      <% end %>
      
      <div class="px-6 py-5">
        <%= render_slot(@inner_block) %>
      </div>
    </div>
    """
  end
end