//+------------------------------------------------------------------+
//|                                      Easy_Triangle_Arbitrage.mq4 |
//|                                  Copyright 2025, MetaQuotes Ltd. |
//|                                             by  Will             |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {

  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+

input double LotSize = 0.1;        // can add more lot
input double Threshold = 0.0001;   // least profit
input bool EnableTrade = false;    // true to enable trading

//+------------------------------------------------------------------+
void OnTick()
{
   double eurusd_ask = MarketInfo("EURUSD", MODE_ASK);
   double usd_eur_bid = MarketInfo("EURUSD", MODE_BID); // ใช้กลับทิศ

   double usdjpy_ask = MarketInfo("USDJPY", MODE_ASK);
   double jpy_usd_bid = MarketInfo("USDJPY", MODE_BID);

   double eurjpy_bid = MarketInfo("EURJPY", MODE_BID);
   double eurjpy_ask = MarketInfo("EURJPY", MODE_ASK);

   if (eurusd_ask == 0 || usdjpy_ask == 0 || eurjpy_bid == 0)
      return;

   // Step 1: convert 1 EUR → to USD
   double usd = 1 * eurusd_ask;

   // Step 2: convert USD to JPY
   double jpy = usd * usdjpy_ask;

   // Step 3: convert JPY back to EUR
   double eur_back = jpy / eurjpy_ask;

   double profit = eur_back - 1;

   if (profit > Threshold)
   {
      Print("Arbitrage opportunity detected! Profit: ", DoubleToString(profit, 6));

      if (EnableTrade)
      {
         int t1 = OrderSend("EURUSD", OP_BUY, LotSize, Ask, 3, 0, 0, "Arb EURUSD", 0, 0, clrBlue);
         int t2 = OrderSend("USDJPY", OP_BUY, LotSize, Ask, 3, 0, 0, "Arb USDJPY", 0, 0, clrRed);
         int t3 = OrderSend("EURJPY", OP_SELL, LotSize, Bid, 3, 0, 0, "Arb EURJPY", 0, 0, clrGreen);

         Print("Trades sent. Ticket numbers: ", t1, ", ", t2, ", ", t3);
      }
   }
}
//+------------------------------------------------------------------+
