defmodule BitcoinExchangeWeb.Components.Feedback.FlashGroup do
  @moduledoc """
  Flash message group component.
  """
  use BitcoinExchangeWeb, :component
  
  alias BitcoinExchangeWeb.Components.Feedback.Flash
  alias BitcoinExchangeWeb.Components.UI.Icon
  alias BitcoinExchangeWeb.Components.JS.Commands

  @doc """
  Shows the flash group with standard titles and content.

  ## Examples

      <.flash_group flash={@flash} />
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :id, :string, default: "flash-group", doc: "the optional id of flash container"

  def flash_group(assigns) do
    ~H"""
    <div id={@id}>
      <Flash.flash kind={:info} title={gettext("Success!")} flash={@flash} />
      <Flash.flash kind={:error} title={gettext("Error!")} flash={@flash} />
      <Flash.flash
        id="client-error"
        kind={:error}
        title={gettext("We can't find the internet")}
        phx-disconnected={Commands.show(".phx-client-error #client-error")}
        phx-connected={Commands.hide("#client-error")}
        hidden
      >
        <%= gettext("Attempting to reconnect") %>
        <Icon.icon name="hero-arrow-path" class="ml-1 h-3 w-3 animate-spin" />
      </Flash.flash>
      
      <Flash.flash
        id="server-error"
        kind={:error}
        title={gettext("Something went wrong!")}
        phx-disconnected={Commands.show(".phx-server-error #server-error")}
        phx-connected={Commands.hide("#server-error")}
        hidden
      >
        <%= gettext("Hang in there while we get back on track") %>
        <Icon.icon name="hero-arrow-path" class="ml-1 h-3 w-3 animate-spin" />
      </Flash.flash>
    </div>
    """
  end
end