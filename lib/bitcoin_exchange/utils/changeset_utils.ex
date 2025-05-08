defmodule BitcoinExchange.Utils.ChangesetUtils do
  @moduledoc """
  Utility functions for working with Ecto changesets.
  
  This module provides helper functions for common changeset operations
  that are used across the application's schemas.
  """
  
  import Ecto.Changeset
  alias Decimal, as: D
  
  @doc """
  Validates that a field is a valid Decimal or can be converted to one.
  
  ## Parameters
  - changeset: The changeset to validate
  - field: The field to validate
  
  ## Returns
  - Updated changeset
  """
  def validate_decimal(changeset, field) do
    validate_change(changeset, field, fn _, value ->
      case convert_to_decimal(value) do
        {:ok, _decimal} -> []
        {:error, reason} -> [{field, reason}]
      end
    end)
  end
  
  @doc """
  Validates that a field is a non-negative Decimal.
  
  ## Parameters
  - changeset: The changeset to validate
  - field: The field to validate
  
  ## Returns
  - Updated changeset
  """
  def validate_non_negative_decimal(changeset, field) do
    validate_decimal(changeset, field)
    |> validate_number(field, greater_than_or_equal_to: 0)
  end
  
  @doc """
  Validates that a field is a positive Decimal.
  
  ## Parameters
  - changeset: The changeset to validate
  - field: The field to validate
  
  ## Returns
  - Updated changeset
  """
  def validate_positive_decimal(changeset, field) do
    validate_decimal(changeset, field)
    |> validate_number(field, greater_than: 0)
  end
  
  @doc """
  Applies a changeset if valid, or returns an error tuple.
  
  ## Parameters
  - changeset: The changeset to apply
  
  ## Returns
  - {:ok, updated_struct} if valid
  - {:error, changeset} if invalid
  """
  def apply_if_valid(changeset) do
    if changeset.valid? do
      {:ok, apply_changes(changeset)}
    else
      {:error, changeset}
    end
  end
  
  @doc """
  Validates that a Decimal field has no more than the specified number of decimal places.
  
  ## Parameters
  - changeset: The changeset to validate
  - field: The field to validate
  - max_decimal_places: The maximum number of decimal places allowed
  
  ## Returns
  - Updated changeset
  """
  def validate_decimal_precision(changeset, field, max_decimal_places) do
    validate_change(changeset, field, fn _, value ->
      if value && is_struct(value, D) do
        decimal_str = D.to_string(value)
        
        case String.split(decimal_str, ".") do
          [_, decimal_part] ->
            if String.length(decimal_part) > max_decimal_places do
              [{field, "must have at most #{max_decimal_places} decimal places"}]
            else
              []
            end
            
          _ ->
            []
        end
      else
        []
      end
    end)
  end
  
  @doc """
  Validates that a field is nil.
  
  ## Parameters
  - changeset: The changeset to validate
  - field: The field to validate
  
  ## Returns
  - Updated changeset
  """
  def validate_nil(changeset, field) do
    validate_change(changeset, field, fn _, value ->
      if value == nil do
        []
      else
        [{field, "must be nil"}]
      end
    end)
  end
  
  @doc """
  Validates that a field is not in the future.
  
  ## Parameters
  - changeset: The changeset to validate
  - field: The field to validate (must be a DateTime)
  - allowance_seconds: Number of seconds allowed in the future (default: 60)
  
  ## Returns
  - Updated changeset
  """
  def validate_not_future_date(changeset, field, allowance_seconds \\ 60) do
    validate_change(changeset, field, fn _, value ->
      now = DateTime.utc_now()
      
      if DateTime.diff(value, now) > allowance_seconds do
        [{field, "cannot be in the future"}]
      else
        []
      end
    end)
  end
  
  @doc """
  Validates that a field contains a valid transaction ID.
  
  ## Parameters
  - changeset: The changeset to validate
  - field: The field to validate
  
  ## Returns
  - Updated changeset
  """
  def validate_transaction_id(changeset, field) do
    validate_change(changeset, field, fn _, value ->
      if valid_transaction_id_format?(value) do
        []
      else
        [{field, "is not a valid transaction ID"}]
      end
    end)
  end
  
  @doc """
  Creates a new changeset with optimistic update semantics.
  Only fields that have changed are included in the changeset.
  
  ## Parameters
  - struct: The struct to create a changeset for
  - params: The params to apply to the struct
  - allowed_fields: The fields that are allowed to be updated
  
  ## Returns
  - A new changeset with only changed fields
  """
  def optimistic_changeset(struct, params, allowed_fields) do
    # Filter out fields that haven't changed
    changed_params =
      for {key, value} <- params,
          Map.get(struct, key) != value,
          key in allowed_fields,
          into: %{} do
        {key, value}
      end
    
    cast(struct, changed_params, allowed_fields)
  end
  
  defp convert_to_decimal(value) when is_nil(value), do: {:error, "cannot be nil"}
  defp convert_to_decimal(value) when is_struct(value, D), do: {:ok, value}
  
  defp convert_to_decimal(value) when is_integer(value) or is_float(value) do
    try do
      {:ok, D.new("#{value}")}
    rescue
      _ -> {:error, "is not a valid number"}
    end
  end
  
  defp convert_to_decimal(value) when is_binary(value) do
    try do
      parsed = D.parse(value)
      case parsed do
        {decimal, ""} -> {:ok, decimal}
        _ -> {:error, "is not a valid number"}
      end
    rescue
      _ -> {:error, "is not a valid number"}
    end
  end
  
  defp convert_to_decimal(_), do: {:error, "is not a valid number"}
  
  defp valid_transaction_id_format?(transaction_id) when is_binary(transaction_id) do
    case String.split(transaction_id, "-") do
      [prefix, timestamp, random, checksum] ->
        valid_prefix?(prefix) && valid_timestamp_format?(timestamp) &&
          valid_random_format?(random) && valid_checksum_format?(checksum)
        
      _ ->
        false
    end
  end
  
  defp valid_transaction_id_format?(_), do: false
  
  defp valid_prefix?(prefix) do
    prefix in ["BUY", "SEL", "ADD", "TXN"]
  end
  
  defp valid_timestamp_format?(timestamp) do
    case Integer.parse(timestamp) do
      {_, ""} -> String.length(timestamp) == 14
      _ -> false
    end
  end
  
  defp valid_random_format?(random) do
    String.length(random) == 10 && String.match?(random, ~r/^[0-9A-F]+$/)
  end
  
  defp valid_checksum_format?(checksum) do
    String.length(checksum) == 1 && String.match?(checksum, ~r/^[0-9A-F]$/)
  end
end