defmodule BitcoinExchangeWeb.Components.UI.ThemeToggle do
  @moduledoc """
  Theme toggle component for switching between light and dark modes.
  """
  use BitcoinExchangeWeb, :component
  alias BitcoinExchangeWeb.Components.UI.Icon

  @doc """
  Renders a theme toggle button that switches between light and dark modes.
  """
  attr :class, :string, default: nil

  def theme_toggle(assigns) do
    ~H"""
    <div
      id="theme-toggle"
      class={[
        "flex items-center justify-center cursor-pointer",
        @class
      ]}
      phx-hook="ThemeToggle"
    >
      <div class="relative h-6 w-12 rounded-full bg-gray-200 dark:bg-gray-600 transition-colors duration-300">
        <div class="absolute left-1 top-1 h-4 w-4 transform rounded-full bg-white transition-transform duration-300 dark:translate-x-6">
        </div>
         <span class="sr-only">Toggle theme</span>
        <div class="pointer-events-none absolute left-1 top-1 flex h-4 w-4 items-center justify-center text-yellow-400 opacity-100 transition-opacity duration-300 dark:opacity-0">
          <Icon.icon name="hero-sun-solid" class="h-3 w-3" />
        </div>
        
        <div class="pointer-events-none absolute right-1 top-1 flex h-4 w-4 items-center justify-center text-gray-700 opacity-0 transition-opacity duration-300 dark:opacity-100">
          <Icon.icon name="hero-moon-solid" class="h-3 w-3" />
        </div>
      </div>
    </div>
    """
  end
end