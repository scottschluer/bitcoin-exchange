defmodule BitcoinExchange.Utils.DecimalUtils do
  @moduledoc """
  Utility functions for working with Decimal types.
  
  Provides safe operations for common Decimal calculations and comparisons,
  handling both Decimal structs and standard numbers.
  """
  alias Decimal, as: D

  @doc """
  Safely creates a new Decimal, handling zero and avoiding float issues.

  ## Examples:
      iex> DecimalUtils.new(10)
      #Decimal<10>

      iex> DecimalUtils.new(10.5)
      #Decimal<10.5>

      iex> DecimalUtils.new("10.5")
      "10.5"
  """
  def new(value) when is_number(value) do
    D.new("#{value}")
  end

  def new(value), do: value

  @doc """
  Gets the absolute value of a Decimal or number.

  ## Examples:
      iex> DecimalUtils.abs(Decimal.new("-10"))
      #Decimal<10>

      iex> DecimalUtils.abs(-10)
      10
  """
  def abs(value) do
    cond do
      is_struct(value, D) ->
        if D.lt?(value, D.new(0)), do: D.negate(value), else: value

      is_number(value) ->
        Kernel.abs(value)

      true ->
        0
    end
  end

  @doc """
  Safely adds two values, handling both Decimal and numbers.

  ## Examples:
      iex> DecimalUtils.add(Decimal.new("10"), Decimal.new("5"))
      #Decimal<15>

      iex> DecimalUtils.add(Decimal.new("10"), 5)
      #Decimal<15>

      iex> DecimalUtils.add(10, Decimal.new("5"))
      #Decimal<15>

      iex> DecimalUtils.add(10, 5)
      15
  """
  def add(a, b) do
    cond do
      is_struct(a, D) && is_struct(b, D) ->
        D.add(a, b)

      is_struct(a, D) && is_number(b) ->
        D.add(a, new(b))

      is_number(a) && is_struct(b, D) ->
        D.add(new(a), b)

      true ->
        a + b
    end
  end

  @doc """
  Safely subtracts two values, handling both Decimal and numbers.

  ## Examples:
      iex> DecimalUtils.sub(Decimal.new("10"), Decimal.new("5"))
      #Decimal<5>

      iex> DecimalUtils.sub(Decimal.new("10"), 5)
      #Decimal<5>

      iex> DecimalUtils.sub(10, Decimal.new("5"))
      #Decimal<5>

      iex> DecimalUtils.sub(10, 5)
      5
  """
  def sub(a, b) do
    cond do
      is_struct(a, D) && is_struct(b, D) ->
        D.sub(a, b)

      is_struct(a, D) && is_number(b) ->
        D.sub(a, new(b))

      is_number(a) && is_struct(b, D) ->
        D.sub(new(a), b)

      true ->
        a - b
    end
  end

  @doc """
  Safely multiplies two values, handling both Decimal and numbers.

  ## Examples:
      iex> DecimalUtils.mult(Decimal.new("10"), Decimal.new("5"))
      #Decimal<50>

      iex> DecimalUtils.mult(Decimal.new("10"), 5)
      #Decimal<50>

      iex> DecimalUtils.mult(10, Decimal.new("5"))
      #Decimal<50>

      iex> DecimalUtils.mult(10, 5)
      50
  """
  def mult(a, b) do
    cond do
      is_struct(a, D) && is_struct(b, D) ->
        D.mult(a, b)

      is_struct(a, D) && is_number(b) ->
        D.mult(a, new(b))

      is_number(a) && is_struct(b, D) ->
        D.mult(new(a), b)

      true ->
        a * b
    end
  end

  @doc """
  Safely divides two values, handling both Decimal and numbers.

  ## Examples:
      iex> DecimalUtils.div(Decimal.new("10"), Decimal.new("5"))
      #Decimal<2>

      iex> DecimalUtils.div(Decimal.new("10"), 5)
      #Decimal<2>

      iex> DecimalUtils.div(10, Decimal.new("5"))
      #Decimal<2>

      iex> DecimalUtils.div(10, 5)
      2.0
  """
  def div(a, b) do
    cond do
      is_struct(a, D) && is_struct(b, D) ->
        D.div(a, b)

      is_struct(a, D) && is_number(b) ->
        D.div(a, new(b))

      is_number(a) && is_struct(b, D) ->
        D.div(new(a), b)

      true ->
        a / b
    end
  end

  @doc """
  Converts a Decimal to float with safe handling of nil values.

  ## Parameters
  - value: The Decimal value to convert
  - default: The default value to return if value is nil

  ## Examples:
      iex> DecimalUtils.to_float(nil, 0.0)
      0.0
      
      iex> DecimalUtils.to_float(Decimal.new("123.45"), 0.0)
      123.45
  """
  def to_float(nil, default), do: default
  def to_float(value, _default) when is_struct(value, D), do: D.to_float(value)
  def to_float(value, _default) when is_float(value), do: value
  def to_float(value, _default) when is_integer(value), do: value * 1.0
  def to_float(value, default) do
    try do
      case new(value) do
        %D{} = decimal -> D.to_float(decimal)
        _ -> default
      end
    rescue
      _ -> default
    end
  end

  @doc """
  Checks if the first value is greater than or equal to the second.

  ## Examples:
      iex> DecimalUtils.gte?(Decimal.new("10"), Decimal.new("5"))
      true

      iex> DecimalUtils.gte?(Decimal.new("10"), 5)
      true

      iex> DecimalUtils.gte?(10, Decimal.new("5"))
      true

      iex> DecimalUtils.gte?(5, 10)
      false
  """
  def gte?(a, b) do
    cond do
      is_struct(a, D) && is_struct(b, D) ->
        D.compare(a, b) in [:gt, :eq]

      is_struct(a, D) && is_number(b) ->
        D.compare(a, new(b)) in [:gt, :eq]

      is_number(a) && is_struct(b, D) ->
        D.compare(new(a), b) in [:gt, :eq]

      true ->
        a >= b
    end
  end

  @doc """
  Checks if the first value is greater than the second.

  ## Examples:
      iex> DecimalUtils.gt?(Decimal.new("10"), Decimal.new("5"))
      true

      iex> DecimalUtils.gt?(Decimal.new("10"), 10)
      false
  """
  def gt?(a, b) do
    cond do
      is_struct(a, D) && is_struct(b, D) ->
        D.gt?(a, b)

      is_struct(a, D) && is_number(b) ->
        D.gt?(a, new(b))

      is_number(a) && is_struct(b, D) ->
        D.gt?(new(a), b)

      true ->
        a > b
    end
  end

  @doc """
  Checks if the first value is less than the second.

  ## Examples:
      iex> DecimalUtils.lt?(Decimal.new("5"), Decimal.new("10"))
      true

      iex> DecimalUtils.lt?(5, 10)
      true
  """
  def lt?(a, b) do
    cond do
      is_struct(a, D) && is_struct(b, D) ->
        D.lt?(a, b)

      is_struct(a, D) && is_number(b) ->
        D.lt?(a, new(b))

      is_number(a) && is_struct(b, D) ->
        D.lt?(new(a), b)

      true ->
        a < b
    end
  end
end