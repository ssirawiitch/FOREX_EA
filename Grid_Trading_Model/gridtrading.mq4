//+------------------------------------------------------------------+
//|                                                 Grid_Trading.mq4 |
//|                                  Copyright 2025, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

// Input parameters for Grid Drawing
input color  GridColor        = clrDodgerBlue; 
input ENUM_LINE_STYLE GridStyle = STYLE_SOLID; // grid style
input int    GridWidth        = 1; // ความกว้างเส้น Grid
input bool   ShowGridLines    = true; // แสดงเส้น Grid บนกราฟหรือไม่

// Global variables for Grid Drawing
string GridObjectNamePrefix = "MyGridLine_"; // Prefix สำหรับตั้งชื่อ Object เส้น Grid

// properties
int input numGrid = 10;
double range = iHigh(Symbol(), PERIOD_W1, 1) - iLow(Symbol(), PERIOD_W1, 1);
double gridSize = range / numGrid;
double store_grid[100]; // Store grid levels
double input lotSize = 0.01;
int input Slippage = 3;

int OnInit()
{
    Print("Grid Trading EA initialized");
    if (ShowGridLines){
        ObjectsDeleteAll(0, 0, OBJ_HLINE);
    }
    return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    Print("Grid Trading EA deinitialized");
    ObjectsDeleteAll(0, 0, OBJ_HLINE);
}

double CalculateGridLevel(int index)
{
    double basePrice = iLow(Symbol(), PERIOD_W1, 1);
    return basePrice + (index * gridSize);
}

datetime prevBarTime = 0;

// Function to check if a new bar has started
bool IsNewBar()
{
    datetime currentTime = iTime(Symbol(), PERIOD_M30, 0); // Get the open time of the current bar
    if (currentTime != prevBarTime){
        prevBarTime = currentTime; 
        return true; 
    }
    return false;
}

void DrawGridLine(double price, int index)
{
    string name = GridObjectNamePrefix + IntegerToString(index);

    // Create a horizontal line object
    if (!ObjectCreate(0, name, OBJ_HLINE, 0, 0, price)) // 0, 0 สำหรับ ChartID, SubWindowIndex ไม่สำคัญสำหรับ HLine
    {
        Print("Failed to create object: ", name, ", Error: ", GetLastError());
        return;
    }

    ObjectSetInteger(0, name, OBJPROP_COLOR, GridColor);
    ObjectSetInteger(0, name, OBJPROP_STYLE, GridStyle);
    ObjectSetInteger(0, name, OBJPROP_WIDTH, GridWidth);
    ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false); 
    ObjectSetInteger(0, name, OBJPROP_HIDDEN, false); 
    ObjectSetInteger(0, name, OBJPROP_BACK, false);  

    // Refresh the chart to display the new object
    ChartRedraw();
}

void OnTick()
{
    // draw grid lines
    if (ShowGridLines && IsNewBar())
    {
        ObjectsDeleteAll(0, 0, OBJ_HLINE); 

        // first calculate grid levels
        for (int i = 0; i <= numGrid; i++){
            store_grid[i] = CalculateGridLevel(i);
        }
        
        // Sort grid levels in descending order
        ArraySort(store_grid, WHOLE_ARRAY, 0);

        // draw grid lines
        for (int i = 0; i <= numGrid; i++){
            DrawGridLine(store_grid[i], i);
        }
    }

    // ถ้าเปลี่ยนแท่ง 30 นาทีให้ยกเลิก buy limit sell limit ของก่อนหน้า
    if(IsNewBar()){
        // Cancel all pending orders
        for (int i = OrdersTotal() - 1; i >= 0; i--) {
            if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
                if (OrderType() == OP_BUYLIMIT || OrderType() == OP_SELLLIMIT) {
                    if (OrderSymbol() == Symbol()) {
                        if (!OrderDelete(OrderTicket())) {
                            Print("Error deleting order: ", GetLastError());
                        }
                    }
                }
            }
        }
    }

    // ถ้าเปลี่ยนแท่ง 30 นาทีให้ reset buy and sell limit orders

    // if new week re calculate grid levels

    // ถ้าถือข้ามวันและยังไม่ปิดทำกำไร ก็จะsl ยอมขาดทุนที่ราคาปิดของวัน

    // เข้าเทรดที่ 30 นาที
    double previousBar = iClose(Symbol(), PERIOD_M30, 1);

    // วนลูปตั้ง buy limit ที่เส้นล่างเส้นเดียวใต้ราคานั้น
    for (int i = 0; i <= numGrid; i++){
        if(previousBar < store_grid[i]) {
            double buyLimitPrice = store_grid[i] - gridSize;
            if (OrderSend(Symbol(), OP_BUYLIMIT, lotSize, buyLimitPrice, Slippage, 0, 0, "Grid Buy Limit", 12347, 0, clrGreen) < 0) {
                Print("Error opening buy limit order: ", GetLastError());
            }
            break; // Exit loop after placing the first buy limit
        }
    }

    // วนลูปตั้ง sell limit ที่เส้นล่างเส้นเดียวบนราคานั้น
    for (int i = 0; i <= numGrid; i++){
        if(previousBar > store_grid[i]) {
            double buyLimitPrice = store_grid[i];
            if (OrderSend(Symbol(), OP_BUYLIMIT, lotSize, buyLimitPrice, Slippage, 0, 0, "Grid Buy Limit", 12348, 0, clrGreen) < 0) {
                Print("Error opening buy limit order: ", GetLastError());
            }
            break; // Exit loop after placing the first buy limit
        }
    }
}

