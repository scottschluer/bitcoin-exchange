defmodule BitcoinExchangeWeb.Components.Layout.Container do
  @moduledoc """
  Container component.
  """
  use BitcoinExchangeWeb, :component

  @doc """
  Renders a container component.
  """
  attr :class, :string, default: nil
  attr :id, :string, default: nil
  slot :inner_block, required: true

  def container(assigns) do
    ~H"""
    <div id={@id} class={["w-full", @class]}>
      <%= render_slot(@inner_block) %>
    </div>
    """
  end
end