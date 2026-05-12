//+------------------------------------------------------------------+
//|                                          GannBot_v3.mq5         |
//|                                     Hossein Parasteh            |
//|                                    github.com/avangardistic     |
//|                                                                  |
//|                   Gann Bot with Dynamic Money Management         |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Hossein Parasteh"
#property link      "https://github.com/avangardistic"
#property version   "3.00"
#property strict
#include <Trade/Trade.mqh>

//=== پارامترهای ورودی ==============================================
// اعداد ثابت برای مدیریت سرمایه
#define MM_FIXED 0
#define MM_RISK_PERCENT 1
#define MM_KELY 2
#define MM_ANTI_MARTINGALE 3

input int            MoneyManagement = MM_RISK_PERCENT; // 0=Fixed,1=Risk%,2=Kelly,3=AntiMartingale
input double         FixedLot = 0.1;                   // حجم ثابت
input double         RiskPercent = 2.0;                // درصد ریسک از سرمایه
input int            StopLoss = 300;                   // حد ضرر (نقطه)
input int            TakeProfit = 600;                 // حد سود (نقطه)
input int            MagicNumber = 12345;              // شماره جادویی
input double         MaxDailyLoss = 5.0;               // حداکثر ضرر روزانه (%)
input int            MaxConsecutiveLosses = 3;         // حداکثر ضرر متوالی
input bool           UseTrailingStop = true;           // استفاده از تریلینگ استاپ
input int            TrailingStart = 200;              // شروع تریلینگ (نقطه)
input int            TrailingStep = 30;                // گام تریلینگ (نقطه)
input ENUM_TIMEFRAMES GannTimeframe = PERIOD_H4;       // تایم‌فریم Gann
input int            Slippage = 30;                    // سلیپیج (نقطه)

//=== متغیرهای سراسری ===============================================
CTrade trade;
int gannHandle;
double currentBalance;
double dailyLoss;
int consecutiveLosses;
datetime lastTradeDate;
int totalTrades;
int winningTrades;
int losingTrades;

//+------------------------------------------------------------------+
//| تابع مقداردهی اولیه                                               |
//+------------------------------------------------------------------+
int OnInit() {
   // بارگذاری اندیکاتور Gann Box
   gannHandle = iCustom(_Symbol, PERIOD_CURRENT, "GannBox", 
                        GannTimeframe, 1, clrGray, clrWhite, clrDodgerBlue, 150);
   
   if(gannHandle == INVALID_HANDLE) {
      Print("Error: Cannot load GannBox indicator");
      return INIT_FAILED;
   }
   
   trade.SetExpertMagicNumber(MagicNumber);
   trade.SetDeviationInPoints(Slippage);
   
   currentBalance = AccountInfoDouble(ACCOUNT_BALANCE);
   dailyLoss = 0;
   consecutiveLosses = 0;
   lastTradeDate = 0;
   totalTrades = 0;
   winningTrades = 0;
   losingTrades = 0;
   
   Print("Gann Bot v3.0 Started");
   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| محاسبه حجم معامله                                                 |
//+------------------------------------------------------------------+
double CalculateLotSize(double entryPrice, double stopLossPrice) {
   double lot = FixedLot;
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double stopDistance = MathAbs(entryPrice - stopLossPrice) / point;
   
   if(stopDistance < 1) stopDistance = 100;
   
   if(MoneyManagement == MM_FIXED) {
      lot = FixedLot;
   }
   else if(MoneyManagement == MM_RISK_PERCENT) {
      double riskAmount = balance * (RiskPercent / 100.0);
      lot = riskAmount / (stopDistance * tickValue);
   }
   else if(MoneyManagement == MM_KELY) {
      double kellyPercent = 0.02;
      if(totalTrades > 20 && losingTrades > 0) {
         double winRate = (double)winningTrades / totalTrades;
         double avgWin = (winningTrades > 0) ? GetAverageWin() : 100;
         double avgLoss = GetAverageLoss();
         if(avgLoss > 0) {
            kellyPercent = winRate - ((1 - winRate) / (avgWin / avgLoss));
            kellyPercent = MathMax(0.01, MathMin(0.25, kellyPercent));
         }
      }
      lot = (balance * kellyPercent) / (stopDistance * tickValue);
   }
   else if(MoneyManagement == MM_ANTI_MARTINGALE) {
      double multiplier = 1.0;
      if(consecutiveLosses > 0) {
         multiplier = 1.0 / (1 + consecutiveLosses * 0.3);
      } else if(winningTrades > losingTrades) {
         int netWins = winningTrades - losingTrades;
         multiplier = 1.0 + MathMin(3, netWins) * 0.25;
      }
      lot = FixedLot * multiplier;
   }
   
   // محدودیت حجم
   double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double maxLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double stepLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   
   if(lot < minLot) lot = minLot;
   if(lot > maxLot) lot = maxLot;
   lot = MathRound(lot / stepLot) * stepLot;
   
   return lot;
}

//+------------------------------------------------------------------+
//| دریافت میانگین سود                                                |
//+------------------------------------------------------------------+
double GetAverageWin() {
   double totalWin = 0;
   int winCount = 0;
   
   for(int i = HistoryDealsTotal() - 1; i >= 0 && winCount < 50; i--) {
      ulong ticket = HistoryDealGetTicket(i);
      if(ticket > 0 && HistoryDealGetInteger(ticket, DEAL_MAGIC) == MagicNumber) {
         double profit = HistoryDealGetDouble(ticket, DEAL_PROFIT);
         if(profit > 0) {
            totalWin += profit;
            winCount++;
         }
      }
   }
   return (winCount > 0) ? totalWin / winCount : 100;
}

//+------------------------------------------------------------------+
//| دریافت میانگین ضرر                                                |
//+------------------------------------------------------------------+
double GetAverageLoss() {
   double totalLoss = 0;
   int lossCount = 0;
   
   for(int i = HistoryDealsTotal() - 1; i >= 0 && lossCount < 50; i--) {
      ulong ticket = HistoryDealGetTicket(i);
      if(ticket > 0 && HistoryDealGetInteger(ticket, DEAL_MAGIC) == MagicNumber) {
         double profit = HistoryDealGetDouble(ticket, DEAL_PROFIT);
         if(profit < 0) {
            totalLoss += MathAbs(profit);
            lossCount++;
         }
      }
   }
   return (lossCount > 0) ? totalLoss / lossCount : 50;
}

//+------------------------------------------------------------------+
//| بررسی حد ضرر روزانه                                                |
//+------------------------------------------------------------------+
bool IsMaxDailyLossReached() {
   datetime now = TimeCurrent();
   MqlDateTime today;
   TimeToStruct(now, today);
   today.hour = 0; today.min = 0; today.sec = 0;
   datetime todayStart = StructToTime(today);
   
   if(lastTradeDate != todayStart) {
      dailyLoss = 0;
      lastTradeDate = todayStart;
      return false;
   }
   
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double dailyLossPercent = (dailyLoss / currentBalance) * 100;
   
   if(dailyLossPercent >= MaxDailyLoss) {
      Print("Daily loss limit reached: ", DoubleToString(dailyLossPercent, 2), "%");
      return true;
   }
   return false;
}

//+------------------------------------------------------------------+
//| اعمال تریلینگ استاپ                                               |
//+------------------------------------------------------------------+
void ApplyTrailingStop() {
   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      ulong ticket = PositionGetTicket(i);
      if(ticket <= 0) continue;
      if(PositionGetInteger(POSITION_MAGIC) != MagicNumber) continue;
      
      double sl = PositionGetDouble(POSITION_SL);
      double tp = PositionGetDouble(POSITION_TP);
      double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
      double currentPrice = (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) ? 
                            SymbolInfoDouble(_Symbol, SYMBOL_BID) : 
                            SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
      
      long type = PositionGetInteger(POSITION_TYPE);
      double profitPoints = (type == POSITION_TYPE_BUY) ? 
                            (currentPrice - openPrice) / point : 
                            (openPrice - currentPrice) / point;
      
      if(profitPoints >= TrailingStart) {
         double newSL = 0;
         if(type == POSITION_TYPE_BUY) {
            newSL = currentPrice - TrailingStep * point;
            if((sl == 0 || newSL > sl) && newSL > openPrice) {
               trade.PositionModify(ticket, newSL, tp);
            }
         } else {
            newSL = currentPrice + TrailingStep * point;
            if((sl == 0 || newSL < sl) && newSL < openPrice) {
               trade.PositionModify(ticket, newSL, tp);
            }
         }
      }
   }
}

//+------------------------------------------------------------------+
//| دریافت ATR جاری                                                  |
//+------------------------------------------------------------------+
double GetCurrentATR() {
   double atr = 0.002;
   int atrHandle = iATR(_Symbol, PERIOD_CURRENT, 14);
   if(atrHandle != INVALID_HANDLE) {
      double atrArray[1];
      if(CopyBuffer(atrHandle, 0, 0, 1, atrArray) > 0 && atrArray[0] > 0) {
         atr = atrArray[0];
      }
      IndicatorRelease(atrHandle);
   }
   return atr;
}

//+------------------------------------------------------------------+
//| بررسی سیگنال خرید                                                 |
//+------------------------------------------------------------------+
bool IsBuySignal() {
   double bottomLine[1];
   if(CopyBuffer(gannHandle, 1, 0, 1, bottomLine) < 1) return false;
   if(bottomLine[0] <= 0) return false;
   
   double price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double atr = GetCurrentATR();
   
   return (price <= bottomLine[0] + atr * 0.5);
}

//+------------------------------------------------------------------+
//| بررسی سیگنال فروش                                                 |
//+------------------------------------------------------------------+
bool IsSellSignal() {
   double topLine[1];
   if(CopyBuffer(gannHandle, 0, 0, 1, topLine) < 1) return false;
   if(topLine[0] <= 0) return false;
   
   double price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double atr = GetCurrentATR();
   
   return (price >= topLine[0] - atr * 0.5);
}

//+------------------------------------------------------------------+
//| بررسی وجود پوزیشن باز                                             |
//+------------------------------------------------------------------+
bool HasBuyPosition() {
   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      ulong ticket = PositionGetTicket(i);
      if(ticket > 0 && PositionGetInteger(POSITION_MAGIC) == MagicNumber) {
         if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) return true;
      }
   }
   return false;
}

bool HasSellPosition() {
   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      ulong ticket = PositionGetTicket(i);
      if(ticket > 0 && PositionGetInteger(POSITION_MAGIC) == MagicNumber) {
         if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL) return true;
      }
   }
   return false;
}

//+------------------------------------------------------------------+
//| تابع اصلی                                                        |
//+------------------------------------------------------------------+
void OnTick() {
   static datetime lastCheck = 0;
   datetime now = TimeCurrent();
   
   if(now - lastCheck < 10) return;
   lastCheck = now;
   
   if(IsMaxDailyLossReached()) return;
   if(consecutiveLosses >= MaxConsecutiveLosses) return;
   if(UseTrailingStop) ApplyTrailingStop();
   
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   
   // سیگنال خرید
   if(IsBuySignal() && !HasBuyPosition()) {
      double sl = bid - StopLoss * point;
      double tp = bid + TakeProfit * point;
      double lot = CalculateLotSize(bid, sl);
      
      if(lot >= SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN)) {
         trade.Buy(lot, _Symbol, ask, sl, tp, "Gann Buy");
      }
   }
   // سیگنال فروش
   else if(IsSellSignal() && !HasSellPosition()) {
      double sl = ask + StopLoss * point;
      double tp = ask - TakeProfit * point;
      double lot = CalculateLotSize(ask, sl);
      
      if(lot >= SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN)) {
         trade.Sell(lot, _Symbol, bid, sl, tp, "Gann Sell");
      }
   }
   
   // نمایش اطلاعات
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double winRate = (totalTrades > 0) ? (double)winningTrades / totalTrades * 100 : 0;
   
   string mmName = "";
   if(MoneyManagement == MM_FIXED) mmName = "Fixed";
   else if(MoneyManagement == MM_RISK_PERCENT) mmName = "Risk%";
   else if(MoneyManagement == MM_KELY) mmName = "Kelly";
   else mmName = "AntiMartingale";
   
   Comment("Gann Bot v3.0 | MM: ", mmName,
           "\nBalance: ", DoubleToString(balance, 2),
           " | Daily Loss: ", DoubleToString(dailyLoss, 2),
           "\nWins: ", winningTrades, " | Losses: ", losingTrades,
           " | Win Rate: ", DoubleToString(winRate, 1), "%",
           "\nConsecutive Losses: ", consecutiveLosses, "/", MaxConsecutiveLosses);
}

//+------------------------------------------------------------------+
//| به‌روزرسانی آمار                                                 |
//+------------------------------------------------------------------+
void OnTrade() {
   int totalDeals = HistoryDealsTotal();
   if(totalDeals > 0) {
      ulong lastTicket = HistoryDealGetTicket(totalDeals - 1);
      if(lastTicket > 0 && HistoryDealGetInteger(lastTicket, DEAL_MAGIC) == MagicNumber) {
         if(HistoryDealGetInteger(lastTicket, DEAL_ENTRY) == DEAL_ENTRY_OUT) {
            double profit = HistoryDealGetDouble(lastTicket, DEAL_PROFIT);
            totalTrades++;
            if(profit > 0) {
               winningTrades++;
               consecutiveLosses = 0;
            } else if(profit < 0) {
               losingTrades++;
               consecutiveLosses++;
               dailyLoss += MathAbs(profit);
            }
            currentBalance = AccountInfoDouble(ACCOUNT_BALANCE);
         }
      }
   }
}

//+------------------------------------------------------------------+
//| تابع خروج                                                        |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
   if(gannHandle != INVALID_HANDLE) IndicatorRelease(gannHandle);
   Comment("");
}
