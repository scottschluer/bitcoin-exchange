# Bitcoin Exchange Application

This project demonstrates a Bitcoin price tracking and trading simulation built with Elixir and Phoenix LiveView.

https://github.com/user-attachments/assets/4dab8174-ce9c-463c-8ef0-02e1e2b7af3a

## Overview

This application simulates a simplified Bitcoin exchange platform where users can:

- Track real-time Bitcoin price updates directly from CoinMarketCap API
- View interactive price charts with live data (mock data for now, ran out of time to implement the live chart data)
- Manage a simulated wallet
- Execute buy/sell transactions based on current market prices

## Technical Highlights

### Elixir/Phoenix Architecture

- **GenServer State Management**: Leverages Elixir's GenServer for maintaining price and wallet state
- **PubSub Pattern**: Implements a publish-subscribe system for real-time price updates
- **Phoenix LiveView**: Creates a reactive UI without writing JavaScript
- **Dependency Injection**: Facilitates testing through configuration-based API client selection

### Frontend Features

- **Interactive Charts**: Displays Bitcoin price trends using browser-based charting
- **Responsive Design**: Built with TailwindCSS for a clean, responsive interface
- **Real-time Updates**: Uses Phoenix Channels and Hooks for live data synchronization

### API Integration

- **Live Market Data**: Fetches real-time price data from CoinMarketCap API
- **Configurable Clients**: Swappable API clients for different data sources
- **Mock Clients**: For development and testing environments
- **Interval-Based Updates**: Configurable polling frequency for latest market data

## Getting Started

### Prerequisites

- Elixir 1.14+
- Erlang 25+
- Node.js 16+

### Installation

```bash
# Clone the repository
git clone https://github.com/scottschluer/bitcoin-exchange

# Install dependencies
mix deps.get
cd assets && npm install

# Set up environment variables 
# (You'll need to configure your CoinMarketCap API key in config/dev.exs or via environment variables)

# Start the Phoenix server
mix phx.server
```

Visit [`localhost:4000`](http://localhost:4000) to see the application running.

## Testing

```bash
# Run the test suite
mix test
```

The test suite includes mock API clients to avoid external API dependencies during testing.
