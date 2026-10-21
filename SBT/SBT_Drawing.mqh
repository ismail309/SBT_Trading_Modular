//+------------------------------------------------------------------+
//|                                                SBT_Drawing.mqh   |
//|                                    Copyright 2026, sbt_trading   |
//|  All chart drawing functions: SL, Levels 1/2/3, ChoCh, ABCDE     |
//|  BoS, zones (MB/DZ/SZ/BBB/QML/DB/SBB/DT), ChoCh confirmation.    |
//+------------------------------------------------------------------+
#ifndef SBT_DRAWING_MQH
#define SBT_DRAWING_MQH

#include "SBT_Utils.mqh"

//+------------------------------------------------------------------+
//| Forward declarations (defined in SBT_Zones.mqh)                  |
//+------------------------------------------------------------------+
void FindClosestPDArray(double level2Price, datetime level2Time, datetime referenceTime);
void FindClosestPDArraySZ(double level2Price, datetime level2Time, datetime referenceTime);
void EnsureSLPriceIsSet();

//+------------------------------------------------------------------+
//| Draw Stop Loss Line                                              |
//+------------------------------------------------------------------+
void DrawStopLossLine(double price, datetime referenceTime)
{
   if(price <= 0 || referenceTime <= 0) return;

   currentSLPrice = price;

   int periodSeconds = PeriodSeconds(PERIOD_CURRENT);
   datetime startTime = referenceTime - (periodSeconds * 10);
   datetime endTime = referenceTime + (periodSeconds * 20);

   ObjectDelete(0, "SL_Line");
   ObjectDelete(0, "SL_Label");

   ObjectCreate(0, "SL_Line", OBJ_TREND, 0, startTime, price, endTime, price);
   ObjectSetInteger(0, "SL_Line", OBJPROP_COLOR, clrRed);
   ObjectSetInteger(0, "SL_Line", OBJPROP_STYLE, STYLE_SOLID);
   ObjectSetInteger(0, "SL_Line", OBJPROP_WIDTH, 2);
   ObjectSetInteger(0, "SL_Line", OBJPROP_BACK, false);
   ObjectSetInteger(0, "SL_Line", OBJPROP_RAY_RIGHT, false);
   ObjectSetInteger(0, "SL_Line", OBJPROP_RAY_LEFT, false);

   double labelPrice;
   if(trendDirection == 1)
   {
      labelPrice = price - (15 * _Point);
      if(_Digits == 5 || _Digits == 3) labelPrice = price - (15 * _Point * 10);
   }
   else
   {
      labelPrice = price + (15 * _Point);
      if(_Digits == 5 || _Digits == 3) labelPrice = price + (15 * _Point * 10);
   }

   ObjectCreate(0, "SL_Label", OBJ_TEXT, 0, startTime + periodSeconds, labelPrice);
   ObjectSetString(0, "SL_Label", OBJPROP_TEXT, "SL");
   ObjectSetInteger(0, "SL_Label", OBJPROP_COLOR, clrRed);
   ObjectSetInteger(0, "SL_Label", OBJPROP_FONTSIZE, 9);
   ObjectSetString(0, "SL_Label", OBJPROP_FONT, "Arial Bold");
   ObjectSetInteger(0, "SL_Label", OBJPROP_ANCHOR, trendDirection == 1 ? ANCHOR_UPPER : ANCHOR_LOWER);
}

//+------------------------------------------------------------------+
//| Draw Level 1 line                                                |
//+------------------------------------------------------------------+
void DrawLevel1Line(double price, datetime time)
{
   level1DrawTime = time;

   int periodSeconds = PeriodSeconds(PERIOD_CURRENT);
   datetime startTime = time - (periodSeconds * 10);
   datetime endTime = time + (periodSeconds * 20);

   ObjectCreate(0, "Level1_Line", OBJ_TREND, 0, startTime, price, endTime, price);
   ObjectSetInteger(0, "Level1_Line", OBJPROP_COLOR, COLOR_LEVEL1);
   ObjectSetInteger(0, "Level1_Line", OBJPROP_STYLE, STYLE_SOLID);
   ObjectSetInteger(0, "Level1_Line", OBJPROP_WIDTH, 2);
   ObjectSetInteger(0, "Level1_Line", OBJPROP_BACK, false);
   ObjectSetInteger(0, "Level1_Line", OBJPROP_RAY_RIGHT, false);
   ObjectSetInteger(0, "Level1_Line", OBJPROP_RAY_LEFT, false);

   double labelPrice = price + (15 * _Point);
   if(_Digits == 5 || _Digits == 3) labelPrice = price + (15 * _Point * 10);

   ObjectCreate(0, "Level1_Label", OBJ_TEXT, 0, startTime + periodSeconds, labelPrice);
   ObjectSetString(0, "Level1_Label", OBJPROP_TEXT, "1. BoS");
   ObjectSetInteger(0, "Level1_Label", OBJPROP_COLOR, COLOR_LEVEL1);
   ObjectSetInteger(0, "Level1_Label", OBJPROP_FONTSIZE, 9);
   ObjectSetString(0, "Level1_Label", OBJPROP_FONT, "Arial Bold");
   ObjectSetInteger(0, "Level1_Label", OBJPROP_ANCHOR, ANCHOR_LOWER);

   currentLevel3Price = 0;
   level3DrawTime = 0;
}

//+------------------------------------------------------------------+
//| Draw Level 3 line                                                |
//+------------------------------------------------------------------+
void DrawLevel3Line(double price, datetime retracementTime, datetime bosBreakTime)
{
   int startBar = iBarShift(_Symbol, PERIOD_CURRENT, retracementTime);
   int endBar = iBarShift(_Symbol, PERIOD_CURRENT, bosBreakTime);
   if(startBar < 0 || endBar < 0) return;

   datetime startCandleTime = iTime(_Symbol, PERIOD_CURRENT, startBar);
   datetime endCandleTime = iTime(_Symbol, PERIOD_CURRENT, endBar);

   int periodSeconds = PeriodSeconds(PERIOD_CURRENT);
   datetime lineStartTime = startCandleTime - (periodSeconds * 10);
   datetime lineEndTime = endCandleTime;

   ObjectCreate(0, "Level3_Line", OBJ_TREND, 0, lineStartTime, price, lineEndTime, price);
   ObjectSetInteger(0, "Level3_Line", OBJPROP_COLOR, COLOR_LEVEL3);
   ObjectSetInteger(0, "Level3_Line", OBJPROP_STYLE, STYLE_SOLID);
   ObjectSetInteger(0, "Level3_Line", OBJPROP_WIDTH, 2);
   ObjectSetInteger(0, "Level3_Line", OBJPROP_BACK, false);
   ObjectSetInteger(0, "Level3_Line", OBJPROP_RAY_RIGHT, false);
   ObjectSetInteger(0, "Level3_Line", OBJPROP_RAY_LEFT, false);

   double labelPrice = price + (15 * _Point);
   if(_Digits == 5 || _Digits == 3) labelPrice = price + (15 * _Point * 10);

   ObjectCreate(0, "Level3_Label", OBJ_TEXT, 0, lineStartTime + periodSeconds, labelPrice);
   ObjectSetString(0, "Level3_Label", OBJPROP_TEXT, "3");
   ObjectSetInteger(0, "Level3_Label", OBJPROP_COLOR, COLOR_LEVEL3);
   ObjectSetInteger(0, "Level3_Label", OBJPROP_FONTSIZE, 9);
   ObjectSetString(0, "Level3_Label", OBJPROP_FONT, "Arial Bold");
   ObjectSetInteger(0, "Level3_Label", OBJPROP_ANCHOR, ANCHOR_LOWER);

   currentLevel3Price = price;
   level3DrawTime = retracementTime;
}

//+------------------------------------------------------------------+
//| Draw Level 2 line                                                |
//+------------------------------------------------------------------+
void DrawLevel2Line(double level2Price, datetime level2Time, datetime bosBreakTime, int &barNumber)
{
   int endBar = iBarShift(_Symbol, PERIOD_CURRENT, bosBreakTime);
   if(endBar < 0) return;

   datetime endCandleTime = iTime(_Symbol, PERIOD_CURRENT, endBar);
   int periodSeconds = PeriodSeconds(PERIOD_CURRENT);
   datetime lineStartTime = level2Time - (periodSeconds * 10);
   datetime lineEndTime = endCandleTime;

   currentChoChLevel = level2Price;
   barNumber = iBarShift(_Symbol, PERIOD_CURRENT, level2Time);

   ObjectCreate(0, "ChoCh_Line", OBJ_TREND, 0, lineStartTime, level2Price, lineEndTime, level2Price);
   ObjectSetInteger(0, "ChoCh_Line", OBJPROP_COLOR, COLOR_LEVEL2);
   ObjectSetInteger(0, "ChoCh_Line", OBJPROP_STYLE, STYLE_SOLID);
   ObjectSetInteger(0, "ChoCh_Line", OBJPROP_WIDTH, 2);
   ObjectSetInteger(0, "ChoCh_Line", OBJPROP_BACK, false);
   ObjectSetInteger(0, "ChoCh_Line", OBJPROP_RAY_RIGHT, false);
   ObjectSetInteger(0, "ChoCh_Line", OBJPROP_RAY_LEFT, false);

   double labelPrice = level2Price - (15 * _Point);
   if(_Digits == 5 || _Digits == 3) labelPrice = level2Price - (15 * _Point * 10);

   ObjectCreate(0, "ChoCh_Label", OBJ_TEXT, 0, lineStartTime + periodSeconds, labelPrice);
   ObjectSetString(0, "ChoCh_Label", OBJPROP_TEXT, "2");
   ObjectSetInteger(0, "ChoCh_Label", OBJPROP_COLOR, COLOR_LEVEL2);
   ObjectSetInteger(0, "ChoCh_Label", OBJPROP_FONTSIZE, 9);
   ObjectSetString(0, "ChoCh_Label", OBJPROP_FONT, "Arial Bold");
   ObjectSetInteger(0, "ChoCh_Label", OBJPROP_ANCHOR, ANCHOR_UPPER);
}

//+------------------------------------------------------------------+
//| Draw ChoCh Confirmation                                          |
//+------------------------------------------------------------------+
void DrawChoChConfirmation(double price, datetime time)
{
   int periodSeconds = PeriodSeconds(PERIOD_CURRENT);
   datetime lineStartTime = time - (periodSeconds * 10);
   double labelPrice = price - (25 * _Point);
   if(_Digits == 5 || _Digits == 3) labelPrice = price - (25 * _Point * 10);

   string labelName = "ChoCh_Confirm_Label_" + TimeToString(time, TIME_DATE|TIME_MINUTES);

   ObjectCreate(0, labelName, OBJ_TEXT, 0, lineStartTime + periodSeconds, labelPrice);
   ObjectSetString(0, labelName, OBJPROP_TEXT, "ChoCh/MsS");
   ObjectSetInteger(0, labelName, OBJPROP_COLOR, clrMagenta);
   ObjectSetInteger(0, labelName, OBJPROP_FONTSIZE, 10);
   ObjectSetString(0, labelName, OBJPROP_FONT, "Arial Bold");
   ObjectSetInteger(0, labelName, OBJPROP_ANCHOR, ANCHOR_UPPER);
   ObjectSetInteger(0, labelName, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, labelName, OBJPROP_HIDDEN, false);
   ObjectSetInteger(0, labelName, OBJPROP_BACK, false);

   Print("📊 ChoCh/MsS Label drawn at ", price, " Time: ", TimeToString(time));
}

//+------------------------------------------------------------------+
//| Draw ABCDE BoS line at Wave C                                    |
//+------------------------------------------------------------------+
void DrawABCDEBoSLine(double bosPrice, datetime bosTime)
{
   if(bosPrice <= 0 || bosTime <= 0) return;

   int periodSeconds = PeriodSeconds(PERIOD_CURRENT);
   datetime lineStartTime = bosTime - (periodSeconds * 10);
   datetime lineEndTime   = bosTime + (periodSeconds * 20);

   ObjectDelete(0, "ABCDE_BoS_Line");
   ObjectDelete(0, "ABCDE_BoS_Label");

   ObjectCreate(0, "ABCDE_BoS_Line", OBJ_TREND, 0, lineStartTime, bosPrice, lineEndTime, bosPrice);
   ObjectSetInteger(0, "ABCDE_BoS_Line", OBJPROP_COLOR, COLOR_LEVEL1);
   ObjectSetInteger(0, "ABCDE_BoS_Line", OBJPROP_STYLE, STYLE_SOLID);
   ObjectSetInteger(0, "ABCDE_BoS_Line", OBJPROP_WIDTH, 2);
   ObjectSetInteger(0, "ABCDE_BoS_Line", OBJPROP_BACK, false);
   ObjectSetInteger(0, "ABCDE_BoS_Line", OBJPROP_RAY_RIGHT, false);
   ObjectSetInteger(0, "ABCDE_BoS_Line", OBJPROP_RAY_LEFT, false);
   ObjectSetInteger(0, "ABCDE_BoS_Line", OBJPROP_SELECTABLE, false);

   double labelPrice = (trendDirection == 1) ? bosPrice + (15 * _Point) : bosPrice - (15 * _Point);
   if(_Digits == 5 || _Digits == 3) labelPrice = (trendDirection == 1) ? bosPrice + (15 * _Point * 10) : bosPrice - (15 * _Point * 10);

   ObjectCreate(0, "ABCDE_BoS_Label", OBJ_TEXT, 0, lineStartTime + periodSeconds, labelPrice);
   ObjectSetString(0, "ABCDE_BoS_Label", OBJPROP_TEXT, "1. BoS (C)");
   ObjectSetInteger(0, "ABCDE_BoS_Label", OBJPROP_COLOR, COLOR_LEVEL1);
   ObjectSetInteger(0, "ABCDE_BoS_Label", OBJPROP_FONTSIZE, 9);
   ObjectSetString(0, "ABCDE_BoS_Label", OBJPROP_FONT, "Arial Bold");
   ObjectSetInteger(0, "ABCDE_BoS_Label", OBJPROP_ANCHOR, trendDirection == 1 ? ANCHOR_LOWER : ANCHOR_UPPER);
   ObjectSetInteger(0, "ABCDE_BoS_Label", OBJPROP_SELECTABLE, false);
}

//+------------------------------------------------------------------+
//| Draw Mitigation Block (MB)                                       |
//+------------------------------------------------------------------+
void DrawMitigationBlock(datetime startTime, double bottomPrice, double topPrice, datetime referenceTime)
{
   Print("========================================");
   Print("📊 DRAW MB - START");
   Print("   startTime: ", startTime > 0 ? TimeToString(startTime) : "NOT SET");
   Print("   bottomPrice: ", bottomPrice > 0 ? DoubleToString(bottomPrice, _Digits) : "NOT SET");
   Print("   topPrice: ", topPrice > 0 ? DoubleToString(topPrice, _Digits) : "NOT SET");
   Print("   referenceTime: ", referenceTime > 0 ? TimeToString(referenceTime) : "NOT SET");
   Print("========================================");

   if(startTime <= 0 || bottomPrice <= 0 || topPrice <= 0) return;
   if(topPrice <= bottomPrice) return;

   mbTopPrice = topPrice;
   mbBottomPrice = bottomPrice;
   mbDrawTime = startTime;
   mbMitigated = false;

   int periodSeconds = PeriodSeconds(PERIOD_CURRENT);
   int leftCandles = ZoneExtensionLeft;
   int rightCandles = ZoneExtensionRight;

   if(leftCandles <= 0) leftCandles = 100;
   if(rightCandles <= 0) rightCandles = 100;

   datetime lineStartTime = referenceTime - (periodSeconds * leftCandles);
   datetime lineEndTime = referenceTime + (periodSeconds * rightCandles);

   ObjectDelete(0, "MB_Rectangle");
   ObjectDelete(0, "MB_Label");

   ObjectCreate(0, "MB_Rectangle", OBJ_RECTANGLE, 0, lineStartTime, topPrice, lineEndTime, bottomPrice);
   ObjectSetInteger(0, "MB_Rectangle", OBJPROP_COLOR, COLOR_MB);
   ObjectSetInteger(0, "MB_Rectangle", OBJPROP_STYLE, STYLE_SOLID);
   ObjectSetInteger(0, "MB_Rectangle", OBJPROP_WIDTH, 1);
   ObjectSetInteger(0, "MB_Rectangle", OBJPROP_FILL, true);
   ObjectSetInteger(0, "MB_Rectangle", OBJPROP_BACK, true);
   ObjectSetInteger(0, "MB_Rectangle", OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, "MB_Rectangle", OBJPROP_HIDDEN, false);

   double midPrice = (topPrice + bottomPrice) / 2.0;
   datetime midTime = lineStartTime + (lineEndTime - lineStartTime) / 2;

   ObjectCreate(0, "MB_Label", OBJ_TEXT, 0, midTime, midPrice);
   ObjectSetString(0, "MB_Label", OBJPROP_TEXT, "MB");
   ObjectSetInteger(0, "MB_Label", OBJPROP_COLOR, clrWhite);
   ObjectSetInteger(0, "MB_Label", OBJPROP_FONTSIZE, 10);
   ObjectSetString(0, "MB_Label", OBJPROP_FONT, "Arial Bold");
   ObjectSetInteger(0, "MB_Label", OBJPROP_ANCHOR, ANCHOR_CENTER);

   Print("✅ MB DRAWN: Bottom=", bottomPrice, " Top=", topPrice);
}

//+------------------------------------------------------------------+
//| Draw Demand Zone (DZ)                                            |
//+------------------------------------------------------------------+
void DrawDemandZone(datetime candleTime, double openPrice, double highPrice, double lowPrice, double level2Price, datetime referenceTime, datetime bosBreakTime)
{
   if(candleTime <= 0 || openPrice <= 0 || level2Price <= 0) return;
   if(openPrice <= level2Price) return;

   dzTopPrice = openPrice;
   dzBottomPrice = level2Price;
   dzDrawTime = candleTime;
   dzCandleHigh = highPrice;
   dzCandleLow = lowPrice;
   dzConfirmed = false;
   dzMitigated = false;
   dzConfirmationBar = 0;

   int periodSeconds = PeriodSeconds(PERIOD_CURRENT);
   int leftCandles = ZoneExtensionLeft;
   int rightCandles = ZoneExtensionRight;

   if(leftCandles <= 0) leftCandles = 100;
   if(rightCandles <= 0) rightCandles = 100;

   datetime lineStartTime = referenceTime - (periodSeconds * leftCandles);
   datetime lineEndTime = referenceTime + (periodSeconds * rightCandles);

   ObjectDelete(0, "DemandZone_Rectangle");
   ObjectDelete(0, "DemandZone_Label");

   ObjectCreate(0, "DemandZone_Rectangle", OBJ_RECTANGLE, 0, lineStartTime, openPrice, lineEndTime, level2Price);
   ObjectSetInteger(0, "DemandZone_Rectangle", OBJPROP_COLOR, COLOR_DZ);
   ObjectSetInteger(0, "DemandZone_Rectangle", OBJPROP_STYLE, STYLE_SOLID);
   ObjectSetInteger(0, "DemandZone_Rectangle", OBJPROP_WIDTH, 1);
   ObjectSetInteger(0, "DemandZone_Rectangle", OBJPROP_FILL, true);
   ObjectSetInteger(0, "DemandZone_Rectangle", OBJPROP_BACK, true);
   ObjectSetInteger(0, "DemandZone_Rectangle", OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, "DemandZone_Rectangle", OBJPROP_HIDDEN, false);

   double midPrice = (openPrice + level2Price) / 2.0;
   datetime midTime = lineStartTime + (lineEndTime - lineStartTime) / 2;

   ObjectCreate(0, "DemandZone_Label", OBJ_TEXT, 0, midTime, midPrice);
   ObjectSetString(0, "DemandZone_Label", OBJPROP_TEXT, "DZ");
   ObjectSetInteger(0, "DemandZone_Label", OBJPROP_COLOR, clrWhite);
   ObjectSetInteger(0, "DemandZone_Label", OBJPROP_FONTSIZE, 10);
   ObjectSetString(0, "DemandZone_Label", OBJPROP_FONT, "Arial Bold");
   ObjectSetInteger(0, "DemandZone_Label", OBJPROP_ANCHOR, ANCHOR_CENTER);

   FindClosestPDArray(level2Price, candleTime, referenceTime);
   EnsureSLPriceIsSet();
   Print("DZ DRAWN: Top=", openPrice, " Bottom=", level2Price);
}

//+------------------------------------------------------------------+
//| Draw Supply Zone (SZ)                                            |
//+------------------------------------------------------------------+
void DrawSupplyZone(datetime candleTime, double openPrice, double highPrice, double lowPrice, double level2Price, datetime referenceTime, datetime bosBreakTime)
{
   if(candleTime <= 0 || openPrice <= 0 || level2Price <= 0) return;
   if(openPrice >= level2Price) return;

   szTopPrice = level2Price;
   szBottomPrice = openPrice;
   szDrawTime = candleTime;
   szCandleLow = lowPrice;
   szCandleHigh = highPrice;
   szConfirmed = false;
   szMitigated = false;
   szConfirmationBar = 0;

   int periodSeconds = PeriodSeconds(PERIOD_CURRENT);
   int leftCandles = ZoneExtensionLeft;
   int rightCandles = ZoneExtensionRight;

   if(leftCandles <= 0) leftCandles = 100;
   if(rightCandles <= 0) rightCandles = 100;

   datetime lineStartTime = referenceTime - (periodSeconds * leftCandles);
   datetime lineEndTime = referenceTime + (periodSeconds * rightCandles);

   ObjectDelete(0, "SupplyZone_Rectangle");
   ObjectDelete(0, "SupplyZone_Label");

   ObjectCreate(0, "SupplyZone_Rectangle", OBJ_RECTANGLE, 0, lineStartTime, level2Price, lineEndTime, openPrice);
   ObjectSetInteger(0, "SupplyZone_Rectangle", OBJPROP_COLOR, COLOR_SZ);
   ObjectSetInteger(0, "SupplyZone_Rectangle", OBJPROP_STYLE, STYLE_SOLID);
   ObjectSetInteger(0, "SupplyZone_Rectangle", OBJPROP_WIDTH, 1);
   ObjectSetInteger(0, "SupplyZone_Rectangle", OBJPROP_FILL, true);
   ObjectSetInteger(0, "SupplyZone_Rectangle", OBJPROP_BACK, true);
   ObjectSetInteger(0, "SupplyZone_Rectangle", OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, "SupplyZone_Rectangle", OBJPROP_HIDDEN, false);

   double midPrice = (level2Price + openPrice) / 2.0;
   datetime midTime = lineStartTime + (lineEndTime - lineStartTime) / 2;

   ObjectCreate(0, "SupplyZone_Label", OBJ_TEXT, 0, midTime, midPrice);
   ObjectSetString(0, "SupplyZone_Label", OBJPROP_TEXT, "SZ");
   ObjectSetInteger(0, "SupplyZone_Label", OBJPROP_COLOR, clrWhite);
   ObjectSetInteger(0, "SupplyZone_Label", OBJPROP_FONTSIZE, 10);
   ObjectSetString(0, "SupplyZone_Label", OBJPROP_FONT, "Arial Bold");
   ObjectSetInteger(0, "SupplyZone_Label", OBJPROP_ANCHOR, ANCHOR_CENTER);

   FindClosestPDArraySZ(level2Price, candleTime, referenceTime);
   EnsureSLPriceIsSet();
   Print("SZ DRAWN: Top=", level2Price, " Bottom=", openPrice);
}

//+------------------------------------------------------------------+
//| Draw Bullish Breaker Block (BBB)                                 |
//+------------------------------------------------------------------+
void DrawBBB(double topPrice, double bottomPrice, datetime referenceTime)
{
   if(topPrice <= 0 || bottomPrice <= 0 || referenceTime <= 0) return;
   if(topPrice <= bottomPrice) return;

   bbbTopPrice = topPrice;
   bbbBottomPrice = bottomPrice;
   bbbDrawTime = referenceTime;
   bbbConfirmed = true;
   bbbMitigated = false;

   int periodSeconds = PeriodSeconds(PERIOD_CURRENT);
   int leftCandles = ZoneExtensionLeft;
   int rightCandles = ZoneExtensionRight;
   if(leftCandles <= 0) leftCandles = 100;
   if(rightCandles <= 0) rightCandles = 100;

   datetime lineStartTime = referenceTime - (periodSeconds * leftCandles);
   datetime lineEndTime = referenceTime + (periodSeconds * rightCandles);

   ObjectDelete(0, "BBB_Rectangle");
   ObjectDelete(0, "BBB_Label");

   ObjectCreate(0, "BBB_Rectangle", OBJ_RECTANGLE, 0, lineStartTime, topPrice, lineEndTime, bottomPrice);
   ObjectSetInteger(0, "BBB_Rectangle", OBJPROP_COLOR, clrDodgerBlue);
   ObjectSetInteger(0, "BBB_Rectangle", OBJPROP_STYLE, STYLE_SOLID);
   ObjectSetInteger(0, "BBB_Rectangle", OBJPROP_WIDTH, 1);
   ObjectSetInteger(0, "BBB_Rectangle", OBJPROP_FILL, true);
   ObjectSetInteger(0, "BBB_Rectangle", OBJPROP_BACK, true);
   ObjectSetInteger(0, "BBB_Rectangle", OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, "BBB_Rectangle", OBJPROP_HIDDEN, false);

   double midPrice = (topPrice + bottomPrice) / 2.0;
   datetime midTime = lineStartTime + (lineEndTime - lineStartTime) / 2;

   ObjectCreate(0, "BBB_Label", OBJ_TEXT, 0, midTime, midPrice);
   ObjectSetString(0, "BBB_Label", OBJPROP_TEXT, "BBB");
   ObjectSetInteger(0, "BBB_Label", OBJPROP_COLOR, clrWhite);
   ObjectSetInteger(0, "BBB_Label", OBJPROP_FONTSIZE, 10);
   ObjectSetString(0, "BBB_Label", OBJPROP_FONT, "Arial Bold");
   ObjectSetInteger(0, "BBB_Label", OBJPROP_ANCHOR, ANCHOR_CENTER);

   Print("BBB DRAWN: Top=", topPrice, " Bottom=", bottomPrice);
}

//+------------------------------------------------------------------+
//| Draw QML                                                         |
//+------------------------------------------------------------------+
void DrawQML(double topPrice, double bottomPrice, datetime referenceTime)
{
   if(topPrice <= 0 || bottomPrice <= 0 || referenceTime <= 0) return;
   if(topPrice <= bottomPrice) return;

   qmlTopPrice = topPrice;
   qmlBottomPrice = bottomPrice;
   qmlDrawTime = referenceTime;
   qmlConfirmed = true;
   qmlMitigated = false;

   int periodSeconds = PeriodSeconds(PERIOD_CURRENT);
   int leftCandles = ZoneExtensionLeft;
   int rightCandles = ZoneExtensionRight;
   if(leftCandles <= 0) leftCandles = 100;
   if(rightCandles <= 0) rightCandles = 100;

   datetime lineStartTime = referenceTime - (periodSeconds * leftCandles);
   datetime lineEndTime = referenceTime + (periodSeconds * rightCandles);

   ObjectDelete(0, "QML_Rectangle");
   ObjectDelete(0, "QML_Label");

   ObjectCreate(0, "QML_Rectangle", OBJ_RECTANGLE, 0, lineStartTime, topPrice, lineEndTime, bottomPrice);
   ObjectSetInteger(0, "QML_Rectangle", OBJPROP_COLOR, clrBlueViolet);
   ObjectSetInteger(0, "QML_Rectangle", OBJPROP_STYLE, STYLE_SOLID);
   ObjectSetInteger(0, "QML_Rectangle", OBJPROP_WIDTH, 1);
   ObjectSetInteger(0, "QML_Rectangle", OBJPROP_FILL, true);
   ObjectSetInteger(0, "QML_Rectangle", OBJPROP_BACK, true);
   ObjectSetInteger(0, "QML_Rectangle", OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, "QML_Rectangle", OBJPROP_HIDDEN, false);

   double midPrice = (topPrice + bottomPrice) / 2.0;
   datetime midTime = lineStartTime + (lineEndTime - lineStartTime) / 2;

   ObjectCreate(0, "QML_Label", OBJ_TEXT, 0, midTime, midPrice);
   ObjectSetString(0, "QML_Label", OBJPROP_TEXT, "QML");
   ObjectSetInteger(0, "QML_Label", OBJPROP_COLOR, clrWhite);
   ObjectSetInteger(0, "QML_Label", OBJPROP_FONTSIZE, 10);
   ObjectSetString(0, "QML_Label", OBJPROP_FONT, "Arial Bold");
   ObjectSetInteger(0, "QML_Label", OBJPROP_ANCHOR, ANCHOR_CENTER);

   Print("QML DRAWN: Top=", topPrice, " Bottom=", bottomPrice);
}

//+------------------------------------------------------------------+
//| Draw Double Bottom (DB)                                          |
//+------------------------------------------------------------------+
void DrawDB(datetime candleTime, double openPrice, double closePrice, double level3Price, datetime referenceTime)
{
   if(candleTime <= 0 || openPrice <= 0 || closePrice <= 0 || level3Price <= 0) return;
   if(openPrice <= level3Price) return;

   dbCandleOpen = openPrice;
   dbCandleClose = closePrice;
   dbTopPrice = openPrice;
   dbBottomPrice = level3Price;
   dbDrawTime = candleTime;
   dbConfirmed = true;
   dbMitigated = false;

   int periodSeconds = PeriodSeconds(PERIOD_CURRENT);
   int leftCandles = ZoneExtensionLeft;
   int rightCandles = ZoneExtensionRight;
   if(leftCandles <= 0) leftCandles = 100;
   if(rightCandles <= 0) rightCandles = 100;

   datetime lineStartTime = referenceTime - (periodSeconds * leftCandles);
   datetime lineEndTime = referenceTime + (periodSeconds * rightCandles);

   ObjectDelete(0, "DB_Rectangle");
   ObjectDelete(0, "DB_Label");

   ObjectCreate(0, "DB_Rectangle", OBJ_RECTANGLE, 0, lineStartTime, openPrice, lineEndTime, level3Price);
   ObjectSetInteger(0, "DB_Rectangle", OBJPROP_COLOR, clrLimeGreen);
   ObjectSetInteger(0, "DB_Rectangle", OBJPROP_STYLE, STYLE_SOLID);
   ObjectSetInteger(0, "DB_Rectangle", OBJPROP_WIDTH, 1);
   ObjectSetInteger(0, "DB_Rectangle", OBJPROP_FILL, true);
   ObjectSetInteger(0, "DB_Rectangle", OBJPROP_BACK, true);
   ObjectSetInteger(0, "DB_Rectangle", OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, "DB_Rectangle", OBJPROP_HIDDEN, false);

   double midPrice = (openPrice + level3Price) / 2.0;
   datetime midTime = lineStartTime + (lineEndTime - lineStartTime) / 2;

   ObjectCreate(0, "DB_Label", OBJ_TEXT, 0, midTime, midPrice);
   ObjectSetString(0, "DB_Label", OBJPROP_TEXT, "DB");
   ObjectSetInteger(0, "DB_Label", OBJPROP_COLOR, clrWhite);
   ObjectSetInteger(0, "DB_Label", OBJPROP_FONTSIZE, 10);
   ObjectSetString(0, "DB_Label", OBJPROP_FONT, "Arial Bold");
   ObjectSetInteger(0, "DB_Label", OBJPROP_ANCHOR, ANCHOR_CENTER);
}

//+------------------------------------------------------------------+
//| Draw SBB (Supply Breaker Block)                                  |
//+------------------------------------------------------------------+
void DrawSBB(double topPrice, double bottomPrice, datetime referenceTime)
{
   if(topPrice <= 0 || bottomPrice <= 0 || referenceTime <= 0) return;
   if(topPrice <= bottomPrice) return;

   sbbTopPrice = topPrice;
   sbbBottomPrice = bottomPrice;
   sbbDrawTime = referenceTime;
   sbbConfirmed = true;
   sbbMitigated = false;

   int periodSeconds = PeriodSeconds(PERIOD_CURRENT);
   int leftCandles = ZoneExtensionLeft;
   int rightCandles = ZoneExtensionRight;
   if(leftCandles <= 0) leftCandles = 100;
   if(rightCandles <= 0) rightCandles = 100;

   datetime lineStartTime = referenceTime - (periodSeconds * leftCandles);
   datetime lineEndTime = referenceTime + (periodSeconds * rightCandles);

   ObjectDelete(0, "SBB_Rectangle");
   ObjectDelete(0, "SBB_Label");

   ObjectCreate(0, "SBB_Rectangle", OBJ_RECTANGLE, 0, lineStartTime, topPrice, lineEndTime, bottomPrice);
   ObjectSetInteger(0, "SBB_Rectangle", OBJPROP_COLOR, clrDarkOrange);
   ObjectSetInteger(0, "SBB_Rectangle", OBJPROP_STYLE, STYLE_SOLID);
   ObjectSetInteger(0, "SBB_Rectangle", OBJPROP_WIDTH, 1);
   ObjectSetInteger(0, "SBB_Rectangle", OBJPROP_FILL, true);
   ObjectSetInteger(0, "SBB_Rectangle", OBJPROP_BACK, true);
   ObjectSetInteger(0, "SBB_Rectangle", OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, "SBB_Rectangle", OBJPROP_HIDDEN, false);

   double midPrice = (topPrice + bottomPrice) / 2.0;
   datetime midTime = lineStartTime + (lineEndTime - lineStartTime) / 2;

   ObjectCreate(0, "SBB_Label", OBJ_TEXT, 0, midTime, midPrice);
   ObjectSetString(0, "SBB_Label", OBJPROP_TEXT, "SBB");
   ObjectSetInteger(0, "SBB_Label", OBJPROP_COLOR, clrWhite);
   ObjectSetInteger(0, "SBB_Label", OBJPROP_FONTSIZE, 10);
   ObjectSetString(0, "SBB_Label", OBJPROP_FONT, "Arial Bold");
   ObjectSetInteger(0, "SBB_Label", OBJPROP_ANCHOR, ANCHOR_CENTER);
}

//+------------------------------------------------------------------+
//| Draw Double Top (DT)                                             |
//+------------------------------------------------------------------+
void DrawDT(datetime candleTime, double openPrice, double closePrice, double level3Price, datetime referenceTime)
{
   if(candleTime <= 0 || openPrice <= 0 || closePrice <= 0 || level3Price <= 0) return;
   if(openPrice >= level3Price) return;

   dtCandleOpen = openPrice;
   dtCandleClose = closePrice;
   dtTopPrice = level3Price;
   dtBottomPrice = openPrice;
   dtDrawTime = candleTime;
   dtConfirmed = true;
   dtMitigated = false;

   int periodSeconds = PeriodSeconds(PERIOD_CURRENT);
   int leftCandles = ZoneExtensionLeft;
   int rightCandles = ZoneExtensionRight;
   if(leftCandles <= 0) leftCandles = 100;
   if(rightCandles <= 0) rightCandles = 100;

   datetime lineStartTime = referenceTime - (periodSeconds * leftCandles);
   datetime lineEndTime = referenceTime + (periodSeconds * rightCandles);

   ObjectDelete(0, "DT_Rectangle");
   ObjectDelete(0, "DT_Label");

   ObjectCreate(0, "DT_Rectangle", OBJ_RECTANGLE, 0, lineStartTime, level3Price, lineEndTime, openPrice);
   ObjectSetInteger(0, "DT_Rectangle", OBJPROP_COLOR, clrCrimson);
   ObjectSetInteger(0, "DT_Rectangle", OBJPROP_STYLE, STYLE_SOLID);
   ObjectSetInteger(0, "DT_Rectangle", OBJPROP_WIDTH, 1);
   ObjectSetInteger(0, "DT_Rectangle", OBJPROP_FILL, true);
   ObjectSetInteger(0, "DT_Rectangle", OBJPROP_BACK, true);
   ObjectSetInteger(0, "DT_Rectangle", OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, "DT_Rectangle", OBJPROP_HIDDEN, false);

   double midPrice = (level3Price + openPrice) / 2.0;
   datetime midTime = lineStartTime + (lineEndTime - lineStartTime) / 2;

   ObjectCreate(0, "DT_Label", OBJ_TEXT, 0, midTime, midPrice);
   ObjectSetString(0, "DT_Label", OBJPROP_TEXT, "DT");
   ObjectSetInteger(0, "DT_Label", OBJPROP_COLOR, clrWhite);
   ObjectSetInteger(0, "DT_Label", OBJPROP_FONTSIZE, 10);
   ObjectSetString(0, "DT_Label", OBJPROP_FONT, "Arial Bold");
   ObjectSetInteger(0, "DT_Label", OBJPROP_ANCHOR, ANCHOR_CENTER);
}

#endif // SBT_DRAWING_MQH
//+------------------------------------------------------------------+