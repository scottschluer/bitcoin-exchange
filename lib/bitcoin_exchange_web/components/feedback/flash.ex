defmodule BitcoinExchangeWeb.Components.Feedback.Flash do
  @moduledoc """
  Flash message component.
  """
  use BitcoinExchangeWeb, :component
  alias Phoenix.LiveView.JS
  alias BitcoinExchangeWeb.Components.UI.Icon
  alias BitcoinExchangeWeb.Components.JS.Commands

  @doc """
  Renders flash notices.

  ## Examples

      <.flash kind={:info} flash={@flash} />
      <.flash kind={:info} phx-mounted={show("#flash")}>Welcome Back!</.flash>
  """
  attr :id, :string, doc: "the optional id of flash container"
  attr :flash, :map, default: %{}, doc: "the map of flash messages to display"
  attr :title, :string, default: nil
  attr :kind, :atom, values: [:info, :error], doc: "used for styling and flash lookup"
  attr :rest, :global, doc: "the arbitrary HTML attributes to add to the flash container"

  slot :inner_block, doc: "the optional inner block that renders the flash message"

  def flash(assigns) do
    assigns = assign_new(assigns, :id, fn -> "flash-#{assigns.kind}" end)

    ~H"""
    <div
      :if={msg = render_slot(@inner_block) || Phoenix.Flash.get(@flash, @kind)}
      id={@id}
      phx-click={JS.push("lv:clear-flash", value: %{key: @kind}) |> Commands.hide("##{@id}")}
      role="alert"
      class={[
        "fixed top-20 right-2 mr-2 w-80 sm:w-96 z-50 rounded-lg p-3 ring-1",
        @kind == :info &&
          "bg-emerald-50 text-emerald-800 ring-emerald-500 fill-cyan-900 dark:bg-emerald-900/50 dark:text-emerald-100 dark:ring-emerald-600",
        @kind == :error &&
          "bg-rose-50 text-rose-900 shadow-md ring-rose-500 fill-rose-900 dark:bg-rose-900/50 dark:text-rose-100 dark:ring-rose-600"
      ]}
      {@rest}
    >
      <p :if={@title} class="flex items-center gap-1.5 text-sm font-semibold leading-6">
        <Icon.icon :if={@kind == :info} name="hero-information-circle-mini" class="h-4 w-4" />
        <Icon.icon :if={@kind == :error} name="hero-exclamation-circle-mini" class="h-4 w-4" /> <%= @title %>
      </p>
      
      <p class="mt-2 text-sm leading-5"><%= msg %></p>
      
      <button type="button" class="group absolute top-1 right-1 p-2" aria-label={gettext("close")}>
        <Icon.icon name="hero-x-mark-solid" class="h-5 w-5 opacity-40 group-hover:opacity-70" />
      </button>
    </div>
    """
  end
end