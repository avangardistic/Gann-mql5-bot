# Gann Bot v3.0

An automated trading bot for MetaTrader 5 built around **Gann Box analysis** and **dynamic money management**.

---

## 📖 Overview

**Gann Bot v3.0** is an automated trading robot designed based on **Gann Boxes** and **dynamic capital management** strategies.  
It enters trades by analyzing dynamic support and resistance levels derived from the **upper and lower boundaries of the Gann Box**.

The bot is built to provide:

- Smarter position sizing
- Advanced risk control
- Flexible parameter customization
- Real-time chart information display

---

## 🚀 Key Features

| Feature | Description |
|--------|-------------|
| 📊 **Dynamic Money Management** | 4 different modes: Fixed Lot, Risk Percentage, Kelly Criterion, and Anti-Martingale |
| 🛡️ **Advanced Risk Control** | Daily loss limit, stop after consecutive losses, trailing stop |
| 📈 **1:2 Risk-to-Reward Ratio** | Default setup uses 300 pips stop loss and 600 pips take profit |
| 🔧 **Fully Customizable** | All parameters can be adjusted by the user |
| 🖥️ **Real-Time Chart Info** | Displays balance, trade status, and statistics directly on the chart |

---

## 📁 Required Files

| File | Path | Description |
|------|------|-------------|
| `GannBot_v3.ex5` | `MQL5/Experts/` | Expert Advisor executable |
| `GannBox.ex5` | `MQL5/Indicators/` | Required Gann Box custom indicator |

> **Important:** The bot depends on the `GannBox` indicator.  
> Both files must be placed in the correct directories.

---

## ⚙️ Input Parameters

### Money Management

| Parameter | Default | Description |
|----------|---------|-------------|
| `MoneyManagement` | `1` (Risk%) | `0 = Fixed Lot`, `1 = Risk Percentage`, `2 = Kelly Criterion`, `3 = Anti-Martingale` |
| `FixedLot` | `0.1` | Fixed trade volume when using `MM_FIXED` |
| `RiskPercent` | `2.0` | Risk percentage per trade when using `MM_RISK_PERCENT` |

### Stop Loss & Take Profit

| Parameter | Default | Description |
|----------|---------|-------------|
| `StopLoss` | `300` | Stop loss in pips |
| `TakeProfit` | `600` | Take profit in pips (`1:2` risk-to-reward ratio) |

### Risk Management

| Parameter | Default | Description |
|----------|---------|-------------|
| `MaxDailyLoss` | `5.0` | Maximum daily loss in percentage |
| `MaxConsecutiveLosses` | `3` | Maximum allowed consecutive losing trades before stopping |
| `UseTrailingStop` | `true` | Enable or disable trailing stop |
| `TrailingStart` | `200` | Start trailing after this many pips in profit |
| `TrailingStep` | `30` | Trailing stop step in pips |

### Timeframe & Execution

| Parameter | Default | Description |
|----------|---------|-------------|
| `GannTimeframe` | `PERIOD_H4` | Gann Box timeframe (`H4`, `D1`, `W1`) |
| `Slippage` | `30` | Maximum allowed slippage in pips |

---

## 🚀 Installation & Setup

### Step 1: Copy the Files

```bash
# Copy indicator
GannBox.ex5  ->  MQL5/Indicators/

# Copy expert advisor
GannBot_v3.ex5  ->  MQL5/Experts/
```

### Step 2: Compile (If Needed)

1. Open **MetaTrader 5**
2. Press **F4** to open **MetaEditor**
3. Open the files and click **Compile (F7)**

### Step 3: Run the Bot

1. In MetaTrader, go to **View → Navigator** or press **Ctrl+N**
2. Open the **Experts** section
3. Double-click **GannBot_v3** or drag it onto a chart
4. Adjust the settings as desired
5. Click **OK**

### Step 4: Test in Strategy Tester

```txt
Symbol: GBPUSD
Period: H4 (recommended)
Date: Any desired range
Optimization: false
```

---

## 📊 Money Management Modes

### 1. Fixed Lot (`MM_FIXED = 0`)
Trades with a constant lot size defined by `FixedLot`.

### 2. Risk Percentage (`MM_RISK_PERCENT = 1`) — Recommended
Each trade risks up to `RiskPercent` percent of account equity.  
Lot size is calculated based on the stop loss distance.

```txt
Formula:
Lot Size = (Account Balance × Risk %) / (Stop Loss Distance × Pip Value)
```

### 3. Kelly Criterion (`MM_KELY = 2`)
Calculates the optimal position size based on historical performance, including win rate and reward/loss ratio.  
Best suited for accounts with enough trading history.

### 4. Anti-Martingale (`MM_ANTI_MARTINGALE = 3`)
- Increase lot size after a winning trade
- Decrease lot size after a losing trade

---

## 🛡️ Risk Management Features

### Daily Loss Limit
If daily loss reaches `MaxDailyLoss`, the bot will stop opening new trades until the next day.

### Consecutive Loss Protection
After `MaxConsecutiveLosses` losing trades in a row, the bot stops trading automatically.

### Trailing Stop
Once the trade reaches `TrailingStart` pips in profit, the stop loss moves forward automatically by `TrailingStep` pips to protect gains.

---

## 📈 Suggested Settings for Different Markets

| Market | Timeframe | StopLoss | TakeProfit | RiskPercent |
|-------|-----------|----------|------------|-------------|
| Forex (GBPUSD) | `H4` | `300` | `600` | `2.0%` |
| Forex (Scalping) | `M15` | `50` | `100` | `1.0%` |
| Gold (XAUUSD) | `H1` | `800` | `1600` | `1.5%` |
| Indices (US30) | `H4` | `500` | `1000` | `1.5%` |

---

## 🔧 Troubleshooting

| Issue | Solution |
|------|----------|
| `cannot load custom indicator 'GannBox'` | Make sure `GannBox.ex5` is copied into the `MQL5/Indicators/` folder |
| `OnInit critical error` | Restart MetaTrader 5 and try again |
| No trades are opened | Make sure the chart timeframe matches `GannTimeframe` |
| Too many consecutive losses | Reduce `RiskPercent` (for example to `1.0%`) |

---

## ⚠️ Disclaimer

```txt
This bot is provided for educational purposes and as a trading assistance tool only.
There is no guarantee of profitability.
Always test the bot on a demo account before using it on a live account.
Proper risk management is the most important part of trading.
```

---

## 📞 Developer

- **GitHub:** [github.com/avangardistic](https://github.com/avangardistic)

---

## 📝 Version History

| Version | Year | Changes |
|--------|------|---------|
| `v3.0` | `2026` | Dynamic money management, trailing stop, improved trade signals |
| `v2.0` | `2026` | Added multiple money management methods |
| `v1.0` | `2026` | Initial release with Gann Box trading logic |

---

## ⭐ Notes

If you use this project and find it helpful, consider giving it a **star** on GitHub.

---

**Trade smart and stay disciplined. 🚀**
اگر خواستی، من همین الان یک **نسخه نهایی و خیلی شیک‌تر GitHub-style** هم برات می‌نویسم.
