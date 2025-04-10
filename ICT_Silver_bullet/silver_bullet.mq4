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

// global vaeriables

bool buy_signal = false;
bool sell_signal = false;
double lotSize;
int ticket;
double bsl = -DBL_MAX;
double ssl = -DBL_MAX;
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

double find_FVG(bool cmd){
    // เกิดเมื่อราคาต้ำสุดของแท่งก่อนหน้ามีค่า สูง ต้ำกว่า ราคาสูงสุดในแท่งก่อนหน้า 3 แท่ง
    
    // Check for Bullish FVG
    if (buy_signal && iLow(Symbol(),0,1) > iHigh(Symbol(),0,3)) {
        zone_start = iLow(Symbol(), 0, 1); 
        // zone_end = iOpen(Symbol(), 0, 1); 
        return zone_start;
    }

    // Check for Bearish FVG
    if (sell_signal && iHigh(Symbol(),0,1) < iLow(Symbol(),0,3)) {
        // zone_start = iOpen(Symbol(), 0, 1);
        zone_end = iHigh(Symbol(), 0, 1);
        return zone_end;
    }

    return 0.00;
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


//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{

  Print("Silver Bullet EA deinitialized");
}
//+------------------------------------------------------------------+

void OnTick()
{

    // find swing high, swing low for checking mss and find FVG
    swing_high = max(iHigh(Symbol(),0,1),swing_high);
    swing_low = min(iLow(Symbol(),0,1),swing_low);

    // first we find BSL and SSL
    if(Is_time_find_hl()){

        double prev = iHigh(Symbol(),0,1);
        double prev2 = iLow(Symbol(),0,1);

        bsl = max(bsl,prev);
        ssl = min(ssl,prev2);
    }

    // trade
    if(Is_time_trade()){

        double prev_price = iHigh(Symbol(),0,1);
        double prev_price2 = iLow(Symbol(),0,1);

        if(Is_sweep_liquidity(prev_price,prev_price2)){
            
            if(buy_signal && Is_mss()){
                // if buy and mss now find zone for trading

                if(find_FVG(Is_mss()) != 0.00){
                    //
                }
            }

            else if(sell_signal && Is_mss()){
                // if sell and mss now find zone for trading

                if(find_FVG(Is_mss()) != 0.00){
                    //
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
    }

}
