//+------------------------------------------------------------------+
//|                                            ICT_Silver_Bullet.mq4 |
//|                                               by Sirawitch(will) |
//|                                  Copyright 2025, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
//+------------------------------------------------------------------+

// global variables

bool buy_signal = false;
bool sell_signal = false;
double lotSize;
int Slippage = 3;
int magicNumber = 12345;
int ticket;
double bsl = -DBL_MAX;
double ssl = DBL_MAX;
double swing_high = -DBL_MAX;
double swing_low = DBL_MAX;

//+------------------------------------------------------------------+
int OnInit()
{
  Print("Silver Bullet EA initialized");
  return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+

// Function

bool Is_sweep_liquidity(double prev_price,double prev_price2){

    if(prev_price > bsl){
        sell_signal = true;
        return true;
    }

    else if(prev_price2 < ssl){
        buy_signal = true;
        return true;
    }

    return false;
}

double find_FVG(){
    // เกิดเมื่อราคาต้ำสุดของแท่งก่อนหน้ามีค่า สูง ต่ำกว่า ราคาสูงสุดในแท่งก่อนหน้า 3 แท่ง
    
    // Check for Bullish FVG
    if (buy_signal && iLow(Symbol(),0,1) > iHigh(Symbol(),0,3)) {
        double zone_start = iLow(Symbol(), 0, 1); 
        // draw FVG in real graph
        draw_FVG_zone("BullishFVG", 1, 3);
        // zone_end = iOpen(Symbol(), 0, 1); 
        return zone_start;
    }

    // Check for Bearish FVG
    if (sell_signal && iHigh(Symbol(),0,1) < iLow(Symbol(),0,3)) {
        // zone_start = iOpen(Symbol(), 0, 1);
        double zone_end = iHigh(Symbol(), 0, 1);
        // draw FVG in real graph
        draw_FVG_zone("BearishFVG", 1, 3);
        return zone_end;
    }

    return 0.0;
}

bool Is_mss() {

    double close_prev = iClose(Symbol(), 0, 1);

    if (buy_signal && close_prev > swing_high) {
        Print("Bullish MSS Confirmed");
        return true;
    }

    if (sell_signal && close_prev < swing_low) {
        Print("Bearish MSS Confirmed");
        return true;
    }

    return false;
}


bool Is_time_trade() {

    datetime now = TimeLocal();
    int hour = TimeHour(now);
    int minute = TimeMinute(now);

    // Thai Time
    if ((hour == 21) || (hour == 22 && minute == 0)) {
        return true;
    }
    return false;
}

bool Is_time_find_hl() {

    // find bsl , ssl 6 hrs before trade
    datetime now = TimeLocal();
    int hour = TimeHour(now);
    int minute = TimeMinute(now);

    if ((hour == 15) || (hour == 20 && minute == 59)) {
        return true;
    }
    return false;
}

void draw_FVG_zone(string name, int candleIndex1, int candleIndex3) {
    double top, bottom;

    if (buy_signal) {
        bottom = iHigh(Symbol(), 0, candleIndex3);  // candle 3 high
        top = iLow(Symbol(), 0, candleIndex1);      // candle 1 low
    } 
    else if (sell_signal) {
        top = iLow(Symbol(), 0, candleIndex3);      // candle 3 low
        bottom = iHigh(Symbol(), 0, candleIndex1);  // candle 1 high
    } 
    else return;

    datetime time1 = iTime(Symbol(), 0, candleIndex1);  // start time
    datetime time2 = Time[0];  // extend to current candle

    string objName = name + "_" + TimeToStr(TimeCurrent(), TIME_MINUTES);

    if (!ObjectCreate(0, objName, OBJ_RECTANGLE, 0, time1, top, time2, bottom)) {
        Print("Failed to draw FVG rectangle");
    }

    ObjectSetInteger(0, objName, OBJPROP_COLOR, clrGold);
    ObjectSetInteger(0, objName, OBJPROP_WIDTH, 1);
    ObjectSetInteger(0, objName, OBJPROP_STYLE, STYLE_DASH);
    ObjectSetInteger(0, objName, OBJPROP_BACK, true);
}


//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{

  Print("Silver Bullet EA deinitialized");
}
//+------------------------------------------------------------------+

void OnTick()
{
    lotSize = MathMax(0.01, NormalizeDouble((AccountBalance() / 1000) * 0.01, 2));

    // find swing high, swing low for checking mss and find FVG
    swing_high = MathMax(iHigh(Symbol(),0,1),swing_high);
    swing_low = MathMin(iLow(Symbol(),0,1),swing_low);

    // first we find BSL and SSL
    if(Is_time_find_hl()){

        double prev = iHigh(Symbol(),0,1);
        double prev2 = iLow(Symbol(),0,1);

        bsl = MathMax(bsl,prev);
        ssl = MathMin(ssl,prev2);
    }

    // trade
    if(Is_time_trade()){

        double prev_price = iHigh(Symbol(),0,1);
        double prev_price2 = iLow(Symbol(),0,1);

        if(Is_sweep_liquidity(prev_price,prev_price2)){
            
            bool mss_confirmed = Is_mss();
            if(buy_signal && mss_confirmed){
                // if buy and mss now find zone for trading

                double zone_price = find_FVG();
                if(zone_price!= 0.0 && ssl<DBL_MAX && bsl > 0 && bsl > Ask){
                    RefreshRates();
                    int buyTicket = OrderSend(Symbol(), OP_BUY, lotSize, Ask, Slippage, ssl, bsl, "Buy Order", magicNumber, 0, clrGreen);

                    if (buyTicket < 0) {
                        Print("Buy Order failed. Error: ", GetLastError());
                    } else {
                        Print("Buy Order success. Ticket: ", buyTicket);
                    }
                }
            }

            else if(sell_signal && mss_confirmed){
                // if sell and mss now find zone for trading

                double zone_price = find_FVG();
                if(zone_price != 0.0 && ssl<DBL_MAX && bsl > 0 && ssl < Bid){
                    RefreshRates();
                    int sellTicket = OrderSend(Symbol(), OP_SELL, lotSize, Bid, Slippage, bsl, ssl, "Sell Order", magicNumber, 0, clrRed);

                    if (sellTicket < 0) {
                        Print("Sell Order failed. Error: ", GetLastError());
                    } else {
                        Print("Sell Order success. Ticket: ", sellTicket);
                    }

                }
            }
        }
    }
   
    // reset all global variables
    if (TimeHour(TimeLocal()) == 23) {

        swing_high = -DBL_MAX;
        swing_low = DBL_MAX;
        buy_signal = false;
        sell_signal = false;
        bsl = -DBL_MAX;
        ssl = DBL_MAX;

        // don't forget to delete all FVG draw!
        for (int i = ObjectsTotal() - 1; i >= 0; i--) {
            string name = ObjectName(i);
            if (StringFind(name, "FVG_Zone_") == 0 || StringFind(name, "BullishFVG") == 0 || StringFind(name, "BearishFVG") == 0) {
                ObjectDelete(name);
            }
        }
    }


}
