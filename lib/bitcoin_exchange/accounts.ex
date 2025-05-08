defmodule BitcoinExchange.Accounts do
  @moduledoc """
  The Accounts context handles user wallet and transaction-related functionality.
  
  This context is responsible for all operations related to a user's financial
  activities including managing cash balance, Bitcoin holdings, and transaction history.
  """
  
  alias BitcoinExchange.Accounts.Services.Wallet
  
  # Re-export the wallet functions for convenience
  defdelegate get_wallet(), to: Wallet
  defdelegate get_transactions(), to: Wallet
  defdelegate add_cash(amount), to: Wallet
  defdelegate update_bitcoin_balance(amount), to: Wallet
  defdelegate buy_bitcoin(btc_amount, btc_price), to: Wallet
  defdelegate sell_bitcoin(btc_amount, btc_price), to: Wallet
  defdelegate calculate_total_value(wallet, btc_price), to: Wallet
end