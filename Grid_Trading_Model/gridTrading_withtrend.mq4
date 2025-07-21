// GridTrader with Trend Filter (EMA 10/50/200 on D1)
#property strict

extern double GridStep = 0.0025;
extern double LotSize = 0.1;
extern int Slippage = 10;
extern int MagicNumber = 12345;
extern double TP_Pips = 0.0025;

// === Helper Functions ===
double GetNearestGrid(double price) {
    double grid = MathFloor(price / GridStep) * GridStep;
    return NormalizeDouble(grid, Digits);
}

bool HasOpenOrderAtGrid(double gridPrice, int type) {
    for (int i = OrdersTotal() - 1; i >= 0; i--) {
        if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
            if (OrderSymbol() != Symbol() || OrderMagicNumber() != MagicNumber) continue;
            if (OrderType() != type) continue;
            double openPrice = NormalizeDouble(OrderOpenPrice(), Digits);
            if (MathAbs(openPrice - gridPrice) < Point * 10) return true;
        }
    }
    return false;
}

void DrawGridLines() {
    double currentPrice = NormalizeDouble(MarketInfo(Symbol(), MODE_BID), Digits);
    double startGrid = GetNearestGrid(currentPrice);
    int range = 40;
    for (int i = -range; i <= range; i++) {
        double level = NormalizeDouble(startGrid + i * GridStep, Digits);
        string lineName = "Grid_" + DoubleToString(level, Digits);
        ObjectDelete(lineName);
        ObjectCreate(lineName, OBJ_HLINE, 0, 0, level);
        ObjectSetInteger(0, lineName, OBJPROP_COLOR, clrGray);
        ObjectSetInteger(0, lineName, OBJPROP_STYLE, STYLE_DOT);
        ObjectSetInteger(0, lineName, OBJPROP_WIDTH, 1);
    }
}

void OpenOrder(int type, double price) {
    double tp = (type == OP_BUY) ? price + TP_Pips : price - TP_Pips;
    tp = NormalizeDouble(tp, Digits);
    price = NormalizeDouble(price, Digits);
    if (type == OP_BUY)
        OrderSend(Symbol(), OP_BUY, LotSize, price, Slippage, 0, tp, "Grid Buy", MagicNumber, 0, clrGreen);
    else if (type == OP_SELL)
        OrderSend(Symbol(), OP_SELL, LotSize, price, Slippage, 0, tp, "Grid Sell", MagicNumber, 0, clrRed);
}

// === Trend Detection using EMA (TF D1) ===
int GetTrend() {
    double ema10 = iMA(Symbol(), PERIOD_D1, 10, 0, MODE_EMA, PRICE_CLOSE, 0);
    double ema50 = iMA(Symbol(), PERIOD_D1, 50, 0, MODE_EMA, PRICE_CLOSE, 0);
    double ema200 = iMA(Symbol(), PERIOD_D1, 200, 0, MODE_EMA, PRICE_CLOSE, 0);

    if (ema10 > ema50 && ema50 > ema200) return 1;   // Uptrend
    if (ema10 < ema50 && ema50 < ema200) return -1;  // Downtrend
    return 0; // Sideway
}

void CloseAllOppositeOrders(int trend) {
    for (int i = OrdersTotal() - 1; i >= 0; i--) {
        if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
            if (OrderSymbol() != Symbol() || OrderMagicNumber() != MagicNumber) continue;
            int type = OrderType();
            if ((trend == 1 && type == OP_SELL) || (trend == -1 && type == OP_BUY)) {
                double price = (type == OP_BUY) ? MarketInfo(Symbol(), MODE_BID) : MarketInfo(Symbol(), MODE_ASK);
                OrderClose(OrderTicket(), OrderLots(), price, Slippage, clrYellow);
            }
        }
    }
}

int OnInit() {
    return INIT_SUCCEEDED;
}

void OnDeinit(const int reason) {
    for (int i = -40; i <= 40; i++) {
        double level = NormalizeDouble(GetNearestGrid(MarketInfo(Symbol(), MODE_BID)) + i * GridStep, Digits);
        string lineName = "Grid_" + DoubleToString(level, Digits);
        ObjectDelete(lineName);
    }
}

void OnTick() {
    if (Period() != PERIOD_M30) return;
    DrawGridLines();

    int trend = GetTrend();
    CloseAllOppositeOrders(trend); // Close positions opposite to trend

    double price = NormalizeDouble(MarketInfo(Symbol(), MODE_ASK), Digits);
    double bid = NormalizeDouble(MarketInfo(Symbol(), MODE_BID), Digits);
    double gridBuy = GetNearestGrid(price);
    double gridSell = GetNearestGrid(bid);

    if (trend == 1 || trend == 0) {
        if (MathAbs(price - gridBuy) < Point * 10 && !HasOpenOrderAtGrid(gridBuy, OP_BUY)) {
            OpenOrder(OP_BUY, gridBuy);
        }
    }
    if (trend == -1 || trend == 0) {
        if (MathAbs(bid - gridSell) < Point * 10 && !HasOpenOrderAtGrid(gridSell, OP_SELL)) {
            OpenOrder(OP_SELL, gridSell);
        }
    }
}