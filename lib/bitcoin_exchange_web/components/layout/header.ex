defmodule BitcoinExchangeWeb.Components.Layout.Header do
  @moduledoc """
  Header component.
  """
  use BitcoinExchangeWeb, :component

  @doc """
  Renders a header with title.
  """
  attr :class, :string, default: nil

  slot :inner_block, required: true
  slot :subtitle
  slot :actions

  def header(assigns) do
    ~H"""
    <header class={[@actions != [] && "flex items-center justify-between gap-6", @class]}>
      <div>
        <h1 class="text-lg font-semibold leading-8 text-zinc-800 dark:text-white">
          <%= render_slot(@inner_block) %>
        </h1>
        
        <p :if={@subtitle != []} class="mt-2 text-sm leading-6 text-zinc-600 dark:text-zinc-400">
          <%= render_slot(@subtitle) %>
        </p>
      </div>
      
      <div class="flex-none"><%= render_slot(@actions) %></div>
    </header>
    """
  end
end