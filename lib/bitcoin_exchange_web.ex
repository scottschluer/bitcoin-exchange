defmodule BitcoinExchangeWeb do
  @moduledoc """
  The entrypoint for defining your web interface, such
  as controllers, components, channels, and so on.

  This can be used in your application as:

      use BitcoinExchangeWeb, :controller
      use BitcoinExchangeWeb, :html

  The definitions below will be executed for every controller,
  component, etc, so keep them short and clean, focused
  on imports, uses and aliases.

  Do NOT define functions inside the quoted expressions
  below. Instead, define additional modules and import
  those modules here.
  """

  def static_paths, do: ~w(assets fonts images favicon.ico robots.txt)

  def router do
    quote do
      use Phoenix.Router, helpers: false

      # Import common connection and controller functions to use in pipelines
      import Plug.Conn
      import Phoenix.Controller
      import Phoenix.LiveView.Router
    end
  end

  def channel do
    quote do
      use Phoenix.Channel
    end
  end

  def controller do
    quote do
      use Phoenix.Controller,
        formats: [:html, :json],
        layouts: [html: BitcoinExchangeWeb.Layouts]

      use Gettext, backend: BitcoinExchangeWeb.Gettext

      import Plug.Conn

      unquote(verified_routes())
    end
  end

  def live_view do
    quote do
      use Phoenix.LiveView,
        layout: {BitcoinExchangeWeb.Layouts, :app}

      unquote(html_helpers())
    end
  end

  def live_component do
    quote do
      use Phoenix.LiveComponent

      unquote(html_helpers())
    end
  end

  def html do
    quote do
      use Phoenix.Component

      # Import convenience functions from controllers
      import Phoenix.Controller,
        only: [get_csrf_token: 0, view_module: 1, view_template: 1]

      # Include general helpers for rendering HTML
      unquote(html_helpers())
    end
  end

  defp html_helpers do
    quote do
      # Translation
      use Gettext, backend: BitcoinExchangeWeb.Gettext

      # HTML escaping functionality
      import Phoenix.HTML
      
      # Core UI components - form components
      import BitcoinExchangeWeb.Components.Form.Button
      import BitcoinExchangeWeb.Components.Form.Input
      import BitcoinExchangeWeb.Components.Form.Label
      import BitcoinExchangeWeb.Components.Form.SimpleForm
      
      # Core UI components - layout components
      import BitcoinExchangeWeb.Components.Layout.Back
      import BitcoinExchangeWeb.Components.Layout.Card
      import BitcoinExchangeWeb.Components.Layout.Container
      import BitcoinExchangeWeb.Components.Layout.Header
      
      # Core UI components - data display components
      import BitcoinExchangeWeb.Components.DataDisplay.List
      import BitcoinExchangeWeb.Components.DataDisplay.Table
      
      # Core UI components - feedback components
      import BitcoinExchangeWeb.Components.Feedback.Error
      import BitcoinExchangeWeb.Components.Feedback.Flash
      import BitcoinExchangeWeb.Components.Feedback.FlashGroup
      
      # Core UI components - overlay components
      import BitcoinExchangeWeb.Components.Overlay.Modal
      
      # Core UI components - UI elements
      import BitcoinExchangeWeb.Components.UI.Icon
      import BitcoinExchangeWeb.Components.UI.ThemeToggle
      
      # Core UI components - JS commands
      import BitcoinExchangeWeb.Components.JS.Commands
      
      # Core UI components - helper functions
      import BitcoinExchangeWeb.Components.Helpers.Translation

      # Shortcut for generating JS commands
      alias Phoenix.LiveView.JS

      # Routes generation with the ~p sigil
      unquote(verified_routes())
    end
  end
  
  def component_helpers do
    quote do
      # Translation
      use Gettext, backend: BitcoinExchangeWeb.Gettext
      
      # HTML escaping functionality
      import Phoenix.HTML
      
      # Shortcut for generating JS commands
      alias Phoenix.LiveView.JS
      
      # Routes generation with the ~p sigil
      unquote(verified_routes())
    end
  end

  def verified_routes do
    quote do
      use Phoenix.VerifiedRoutes,
        endpoint: BitcoinExchangeWeb.Endpoint,
        router: BitcoinExchangeWeb.Router,
        statics: BitcoinExchangeWeb.static_paths()
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/live_view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
  
  def component do
    quote do
      use Phoenix.Component
      unquote(component_helpers())
    end
  end
end
