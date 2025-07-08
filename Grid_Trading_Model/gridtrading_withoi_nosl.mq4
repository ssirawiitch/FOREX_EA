// in this version we use oi (strike price) to be lines (0.005,0.0025)
//+------------------------------------------------------------------+
//|                                                   GridTrader.mq4 |
//|                                Custom Grid Trading EA for EURUSD |
//|                                                          by Will |
//+------------------------------------------------------------------+
#property strict

extern double GridStep = 0.0025;    // ระยะห่างระหว่างเส้น
extern double LotSize = 0.01;        // Lot Size
extern int Slippage = 10;            // Slippage protect error 138
extern int MagicNumber = 12345;     // Magic Number
extern double TP_Pips = 0.0025;     // TP เท่ากับระยะห่าง 1 เส้น

// ฟังก์ชันช่วยคำนวณ Grid Level ปัจจุบันจากราคา
double GetNearestGrid(double price) {
    double grid = MathFloor(price / GridStep) * GridStep;
    return NormalizeDouble(grid, Digits);
}

// ฟังก์ชันตรวจสอบว่า Grid Level นี้มี Order อยู่หรือไม่
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

    int range = 40; // จำนวนเส้น grid ด้านบนและล่าง (40 x 0.0025 ≈ 100 pips)
    for (int i = -range; i <= range; i++) {
        double level = NormalizeDouble(startGrid + i * GridStep, Digits);
        string lineName = "Grid_" + DoubleToString(level, Digits);

        // ถ้ามีอยู่แล้วให้ลบก่อนวาดใหม่
        ObjectDelete(lineName);

        ObjectCreate(lineName, OBJ_HLINE, 0, 0, level);
        ObjectSetInteger(0, lineName, OBJPROP_COLOR, clrGray);
        ObjectSetInteger(0, lineName, OBJPROP_STYLE, STYLE_DOT);
        ObjectSetInteger(0, lineName, OBJPROP_WIDTH, 1);
    }
}


// ฟังก์ชันเปิด Order
void OpenOrder(int type, double price) {
    double tp = (type == OP_BUY) ? price + TP_Pips : price - TP_Pips;
    tp = NormalizeDouble(tp, Digits);
    price = NormalizeDouble(price, Digits);

    if (type == OP_BUY) {
        OrderSend(Symbol(), OP_BUY, LotSize, price, Slippage, 0, tp, "Grid Buy", MagicNumber, 0, clrGreen);
    } else if (type == OP_SELL) {
        OrderSend(Symbol(), OP_SELL, LotSize, price, Slippage, 0, tp, "Grid Sell", MagicNumber, 0, clrRed);
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

    double price = NormalizeDouble(MarketInfo(Symbol(), MODE_ASK), Digits);
    double bid = NormalizeDouble(MarketInfo(Symbol(), MODE_BID), Digits);

    double gridBuy = GetNearestGrid(price);
    double gridSell = GetNearestGrid(bid);

    // Buy Grid
    if (MathAbs(price - gridBuy) < Point * 10) {
        if (!HasOpenOrderAtGrid(gridBuy, OP_BUY)) {
            OpenOrder(OP_BUY, gridBuy);
        }
    }

    // Sell Grid
    if (MathAbs(bid - gridSell) < Point * 10) {
        if (!HasOpenOrderAtGrid(gridSell, OP_SELL)) {
            OpenOrder(OP_SELL, gridSell);
        }
    }
}

// manage stop-loss

