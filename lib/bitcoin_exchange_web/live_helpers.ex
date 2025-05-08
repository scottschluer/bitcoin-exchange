defmodule BitcoinExchangeWeb.LiveHelpers do
  @moduledoc """
  Common helper functions for LiveView components.
  
  This module provides helper functions and common patterns used across
  LiveView components to reduce duplication and standardize operations.
  """
  
  import Phoenix.Component
  
  @doc """
  Updates the socket assigns with the new data and returns the updated socket.
  
  ## Parameters
  - socket: The LiveView socket to update
  - assigns: Map of assigns to update
  """
  def update_socket_assigns(socket, assigns) do
    assign(socket, assigns)
  end
  
  @doc """
  Push an event to set an input value using JS hooks.
  
  ## Parameters
  - socket: The LiveView socket
  - id: The input element id
  - value: The value to set
  """
  def push_input_value(socket, id, value) do
    Phoenix.LiveView.push_event(socket, "set_input_value", %{
      id: id,
      value: value
    })
  end
  
  @doc """
  Shows an error message in the form when a transaction fails.
  
  ## Parameters
  - socket: The LiveView socket
  - error: The error message to display
  """
  def show_form_error(socket, error) do
    assign(socket, form_error: error)
  end
  
  @doc """
  Clears any form errors and closes modal forms.
  
  ## Parameters
  - socket: The LiveView socket
  """
  def clear_form_and_error(socket) do
    assign(socket, modal_form: nil, form_error: nil)
  end
  
  @doc """
  Opens a modal form of the specified type.
  
  ## Parameters
  - socket: The LiveView socket
  - form_type: The type of form to display
  """
  def open_modal_form(socket, form_type) do
    assign(socket, modal_form: form_type, form_error: nil)
  end
end