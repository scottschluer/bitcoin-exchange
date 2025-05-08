defmodule BitcoinExchangeWeb.Components.DataDisplay.List do
  @moduledoc """
  List component for displaying data.
  """
  use BitcoinExchangeWeb, :component

  @doc """
  Renders a data list.

  ## Examples

      <.list>
        <:item title="Title">{@post.title}</:item>
        <:item title="Views">{@post.views}</:item>
      </.list>
  """
  slot :item, required: true do
    attr :title, :string, required: true
  end

  def list(assigns) do
    ~H"""
    <div class="mt-14">
      <dl class="-my-4 divide-y divide-zinc-100 dark:divide-zinc-800">
        <div :for={item <- @item} class="flex gap-4 py-4 text-sm leading-6 sm:gap-8">
          <dt class="w-1/4 flex-none text-zinc-500 dark:text-zinc-400"><%= item.title %></dt>
          
          <dd class="text-zinc-700 dark:text-zinc-300"><%= render_slot(item) %></dd>
        </div>
      </dl>
    </div>
    """
  end
end