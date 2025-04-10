//+------------------------------------------------------------------+
//|                          CrossEMA-50-175_will.mq4                |
//|                  Fixed and Improved by Will (2025)           |
//|                                  MetaQuotes Ltd.                 |
//|                                       https://www.mql5.com       |
//+------------------------------------------------------------------+
#property strict

//+------------------------ Expert Properties ------------------------+
int Slippage = 3;
int magicNumber = 12345;
double lotSize;
bool check;
int ticket;

//+------------------------ Initialization ---------------------------+
int OnInit()
{
    Print("CrossEMA-21-55 EA Initialized");
    return INIT_SUCCEEDED;
}

//+------------------------ Deinitialization -------------------------+
void OnDeinit(const int reason)
{
    Print("CrossEMA-21-55 EA Deinitialized");
}

//+------------------------ Main Trading Logic -----------------------+
void OnTick()
{
    lotSize = MathMax(0.01, NormalizeDouble((AccountBalance() / 1000) * 0.01, 2));

    double fast_ema = iMA(NULL, PERIOD_CURRENT , 21, 0, MODE_EMA, PRICE_CLOSE, 0);
    double slow_ema = iMA(NULL, PERIOD_CURRENT , 55, 0, MODE_EMA, PRICE_CLOSE, 0);
    double prev_fast_ema = iMA(NULL, PERIOD_CURRENT , 21, 0, MODE_EMA, PRICE_CLOSE, 1);
    double prev_slow_ema = iMA(NULL, PERIOD_CURRENT , 55, 0, MODE_EMA, PRICE_CLOSE, 1);

    int totalOrders = OrdersTotal();
    int openOrderType = 0;
    int orderTicket = -1;

    for (int i = 0; i < totalOrders; i++)
    {
        if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
        {
            if (OrderMagicNumber() == magicNumber)
            {
                orderTicket = OrderTicket();
                if (OrderType() == OP_BUY)
                    openOrderType = 1;
                else if (OrderType() == OP_SELL)
                    openOrderType = -1;
                break;
            }
        }
    }

    // **Entry Condition: If no open orders, place a new one**
    if (openOrderType == 0)
    {
        if (prev_fast_ema < prev_slow_ema && fast_ema > slow_ema) // Buy Condition
        {
            int buyTicket = OrderSend(Symbol(), OP_BUY, lotSize, Ask, Slippage, 0, 0, "Buy Order", magicNumber, 0, clrGreen);
            if (buyTicket > 0)
                Print("Buy Order Placed Successfully");
            else
                Print("Buy Order Failed: ", GetLastError());
        }
        else if (prev_fast_ema > prev_slow_ema && fast_ema < slow_ema) // Sell Condition
        {
            int sellTicket = OrderSend(Symbol(), OP_SELL, lotSize, Bid, Slippage, 0, 0, "Sell Order", magicNumber, 0, clrRed);
            if (sellTicket > 0)
                Print("Sell Order Placed Successfully");
            else
                Print("Sell Order Failed: ", GetLastError());
        }
    }

    // **Exit Condition: Close existing orders if crossover happens**
    else if (openOrderType == 1 && prev_fast_ema > prev_slow_ema && fast_ema < slow_ema) // Close Buy and Sell
    {
        if (OrderClose(orderTicket, OrderLots(), Bid, Slippage))
            Print("Closed Buy Order Successfully");
        else
            Print("Failed to Close Buy Order: ", GetLastError());

        // Open Sell Order
        int sellTicket = OrderSend(Symbol(), OP_SELL, lotSize, Bid, Slippage, 0, 0, "Sell Order", magicNumber, 0, clrRed);
        if (sellTicket > 0)
            Print("Sell Order Placed Successfully");
        else
            Print("Sell Order Failed: ", GetLastError());
    }
    else if (openOrderType == -1 && prev_fast_ema < prev_slow_ema && fast_ema > slow_ema) // Close Sell and Buy
    {
        if (OrderClose(orderTicket, OrderLots(), Ask, Slippage))
            Print("Closed Sell Order Successfully");
        else
            Print("Failed to Close Sell Order: ", GetLastError());

        // Open Buy Order
        int buyTicket = OrderSend(Symbol(), OP_BUY, lotSize, Ask, Slippage, 0, 0, "Buy Order", magicNumber, 0, clrGreen);
        if (buyTicket > 0)
            Print("Buy Order Placed Successfully");
        else
            Print("Buy Order Failed: ", GetLastError());
    }
}
