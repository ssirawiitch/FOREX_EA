//+------------------------------------------------------------------+
//|                                        Pair_Trading_Strategy.mq4 |
//|                                               by Sirawitch(will) |
//|                                  Copyright 2025, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
// we will use NZDUSD and AUDUSD for pair trading strategy 
// (u can see why in the latest jupyter notebook)
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
//+------------------------------------------------------------------+

// inputs
input int    lookback   = 100;          // จำนวนแท่งที่ใช้คำนวณ   (latest version is 50)
input double entryZ     = 3.0;          // Z-score ที่ใช้เปิด order  (latest version is 2.0)
input double exitZ      = 0.5;          // Z-score ที่ใช้ปิด order
input double lotSize    = 0.01;         // ขนาดล็อต
input double stopZ      = 3.5;          // Z-score ที่ใช้ปิด orderแบบ stop loss

// variables
double spreadHistory[1000];
double lastZ = 0;

int OnInit()
{
    ArraySetAsSeries(spreadHistory, true);   // at index 0 is the most recent value unlike normal array
    Print("Pair Trading Strategy EA initialized");
    return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    Print("Pair Trading Strategy EA deinitialized"); 
}

// Function to calculate std
double StdDev(double &arr[], int len) {
    double sum = 0, mean = 0, sd = 0;
    for (int i = 0; i < len; i++) sum += arr[i];
    mean = sum / len;
    for (int i = 0; i < len; i++) sd += MathPow(arr[i] - mean, 2);
    return MathSqrt(sd / len);
}

void OnTick()
{
    // calculate current price
    double priceAUD = iClose("AUDUSD#", PERIOD_H1, 0);  // latest version is M15
    double priceNZD = iClose("NZDUSD#", PERIOD_H1, 0);
    double spread   = priceAUD - priceNZD;
    datetime last_bar_time = 0;

    // จะได้ไม่ต้องโหลดข้อมูลหลายๆรอบ ช้า
    if (Time[0] != last_bar_time) { // Check for new bar
        last_bar_time = Time[0];
        for (int i = 0; i < lookback; i++) {
            spreadHistory[i] = iClose("AUDUSD#", PERIOD_H1, i) - iClose("NZDUSD#", PERIOD_H1, i);
        }
    }

    // calculate Z-score
    double mean = iMAOnArray(spreadHistory, 0, lookback, 0, MODE_SMA, 0);
    double stddev = StdDev(spreadHistory, lookback);
    if (stddev == 0) return; // avoid division by zero
    double z = (spread - mean) / stddev;
    lastZ = z;

    Comment("Z-Score: ", DoubleToString(z, 2), "\nSpread: ", DoubleToString(spread, 5));

    // order entry
    if (z >= entryZ && OrdersTotal() == 0) {
        // Short AUD, Long NZD
        int ticket1 = OrderSend("AUDUSD#", OP_SELL, lotSize, Bid, 4, 0, 0, "Short AUD", 12345, 0, clrRed);
        int ticket2 = OrderSend("NZDUSD#", OP_BUY, lotSize, Ask, 4, 0, 0, "Long NZD", 12346, 0, clrGreen);
    }

    if (z <= -entryZ && OrdersTotal() == 0) {
        // Long AUD, Short NZD
        int ticket3 = OrderSend("AUDUSD#", OP_BUY, lotSize, Ask, 4, 0, 0, "Long AUD", 12347, 0, clrBlue);
        int ticket4 = OrderSend("NZDUSD#", OP_SELL, lotSize, Bid, 4, 0, 0, "Short NZD", 12348, 0, clrOrange);
    }

    // order exit
    if ((MathAbs(z) < exitZ && OrdersTotal() > 0) || (MathAbs(z) >= stopZ && OrdersTotal() > 0) || (TimeCurrent() - OrderOpenTime() >= 7200 && OrdersTotal() > 0)) {
        for (int i = OrdersTotal() - 1; i >= 0; i--) {
            if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
                string sym = OrderSymbol();
                if (sym == "AUDUSD#" || sym == "NZDUSD#") {
                    double closePrice = (OrderType() == OP_BUY) ? Bid : Ask;
                    if (OrderClose(OrderTicket(), OrderLots(), closePrice, 2, clrGray)) {
                        Print("Closed order: ", sym, " Ticket: ", OrderTicket());
                    } else {
                        int err = GetLastError();
                        Print("Failed to close order ", sym, " Ticket: ", OrderTicket(), " | Error: ", err);
                    }
                }
            }
        }
    }
}