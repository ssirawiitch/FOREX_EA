
# Pair Trading Strategy EA

## Overview
A MetaTrader 4 Expert Advisor that implements a **pairs trading strategy** using NZDUSD and AUDUSD. The strategy detects price divergences between the two currency pairs and profits from mean reversion.

## How It Works

### 1. **Core Concept**
- Calculates the **spread** (price difference) between AUDUSD and NZDUSD
- Uses **Z-score** to measure how far the spread deviates from its average
- Opens trades when divergence is extreme; closes when prices revert to normal

### 2. **Key Inputs**
| Parameter | Default | Purpose |
|-----------|---------|---------|
| `lookback` | 100 | Bars used for mean/std deviation calculation |
| `entryZ` | 3.0 | Z-score threshold to enter a trade |
| `exitZ` | 0.5 | Z-score threshold to exit a trade |
| `stopZ` | 3.5 | Z-score threshold for stop loss |
| `lotSize` | 0.01 | Trade position size |

### 3. **Trading Logic**

**Entry Signals:**
- **Z ≥ +3.0**: AUD overpriced relative to NZD → **Short AUD, Long NZD**
- **Z ≤ -3.0**: NZD overpriced relative to AUD → **Long AUD, Short NZD**

**Exit Signals (Close all pairs):**
- Z returns to ±0.5 (mean reversion)
- Z reaches ±3.5 (stop loss)
- Trade held for 2+ hours (7200 seconds)

### 4. **Key Functions**
- `StdDev()`: Calculates standard deviation of spread history
- `OnTick()`: Main logic executed on each price tick
- Z-score formula: `(current_spread - mean) / standard_deviation`
