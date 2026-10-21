//+------------------------------------------------------------------+
//|                                                  SBT_Zones.mqh   |
//|                                    Copyright 2026, sbt_trading   |
//|  Zone detection & mitigation status, PD-array / SL finders,      |
//|  mitigation block finder, SL price ensure.                       |
//+------------------------------------------------------------------+
#ifndef SBT_ZONES_MQH
#define SBT_ZONES_MQH

#include "SBT_Drawing.mqh"

//+------------------------------------------------------------------+
//| Find Breaking Candle DZ (Bullish)                                |
//+------------------------------------------------------------------+
int FindBreakingCandleDZ(double demandCandleHigh, datetime startTime, double &demandLow,
                          double &demandOpen, double &demandClose, datetime &confirmationTime)
{
   if(demandCandleHigh <= 0 || startTime <= 0) return -1;
   int startBar = iBarShift(_Symbol, PERIOD_CURRENT, startTime);
   if(startBar < 0) return -1;

   demandLow = iLow(_Symbol, PERIOD_CURRENT, startBar);
   demandOpen = iOpen(_Symbol, PERIOD_CURRENT, startBar);
   demandClose = iClose(_Symbol, PERIOD_CURRENT, startBar);

   for(int i = startBar - 1; i >= 1; i--)
   {
      double close = iClose(_Symbol, PERIOD_CURRENT, i);
      if(close > demandCandleHigh)
      {
         confirmationTime = iTime(_Symbol, PERIOD_CURRENT, i);
         return i;
      }
   }
   return -1;
}

//+------------------------------------------------------------------+
//| Find Breaking Candle SZ (Bearish)                                |
//+------------------------------------------------------------------+
int FindBreakingCandleSZ(double supplyCandleLow, datetime startTime, double &supplyHigh,
                          double &supplyOpen, double &supplyClose, datetime &confirmationTime)
{
   if(supplyCandleLow <= 0 || startTime <= 0) return -1;
   int startBar = iBarShift(_Symbol, PERIOD_CURRENT, startTime);
   if(startBar < 0) return -1;

   supplyHigh = iHigh(_Symbol, PERIOD_CURRENT, startBar);
   supplyOpen = iOpen(_Symbol, PERIOD_CURRENT, startBar);
   supplyClose = iClose(_Symbol, PERIOD_CURRENT, startBar);

   for(int i = startBar - 1; i >= 1; i--)
   {
      double close = iClose(_Symbol, PERIOD_CURRENT, i);
      if(close < supplyCandleLow)
      {
         confirmationTime = iTime(_Symbol, PERIOD_CURRENT, i);
         return i;
      }
   }
   return -1;
}

//+------------------------------------------------------------------+
//| Demand Candle Mitigation (Condition B)                           |
//+------------------------------------------------------------------+
bool IsDemandCandleMitigated(double candleHigh, double candleLow, datetime candleTime,
                              datetime confirmationTime, datetime level1Time)
{
   if(candleHigh <= 0 || candleLow <= 0 || candleTime <= 0 || confirmationTime <= 0 || level1Time <= 0) return false;
   if(candleHigh <= candleLow) return false;

   int demandBar = iBarShift(_Symbol, PERIOD_CURRENT, candleTime);
   int confirmBar = iBarShift(_Symbol, PERIOD_CURRENT, confirmationTime);
   int level1Bar = iBarShift(_Symbol, PERIOD_CURRENT, level1Time);
   if(demandBar < 0 || confirmBar < 0 || level1Bar < 0) return false;

   int startCheck = confirmBar - 1;
   if(startCheck < 1) startCheck = 1;
   int endCheck = level1Bar;
   if(endCheck < 1) endCheck = 1;

   for(int i = startCheck; i >= endCheck; i--)
   {
      if(i == demandBar || i == confirmBar) continue;

      double high = iHigh(_Symbol, PERIOD_CURRENT, i);
      double low = iLow(_Symbol, PERIOD_CURRENT, i);

      if(high >= candleLow && low <= candleHigh)
         return true;
   }
   return false;
}

//+------------------------------------------------------------------+
//| Check if supply candle is mitigated (BEFORE BoS - Condition B)   |
//+------------------------------------------------------------------+
bool IsSupplyCandleMitigated(double candleHigh, double candleLow, datetime candleTime, datetime level1Time)
{
   if(candleHigh <= 0 || candleLow <= 0 || candleTime <= 0 || level1Time <= 0) return false;
   if(candleHigh <= candleLow) return false;

   int supplyBar = iBarShift(_Symbol, PERIOD_CURRENT, candleTime);
   int level1Bar = iBarShift(_Symbol, PERIOD_CURRENT, level1Time);
   if(supplyBar < 0 || level1Bar < 0) return false;

   for(int i = supplyBar - 1; i > level1Bar; i--)
   {
      double high = iHigh(_Symbol, PERIOD_CURRENT, i);
      double low = iLow(_Symbol, PERIOD_CURRENT, i);

      if(high >= candleLow && low <= candleHigh)
         return true;
   }
   return false;
}

//+------------------------------------------------------------------+
//| DZ Mitigation                                                    |
//+------------------------------------------------------------------+
bool IsDZMitigatedAfterBoS(double zoneBottom, int confirmationBar)
{
   if(zoneBottom <= 0 || confirmationBar <= 0) return false;

   for(int i = confirmationBar - 1; i >= 1; i--)
   {
      double close = iClose(_Symbol, PERIOD_CURRENT, i);
      if(close < zoneBottom) return true;
   }
   return false;
}

//+------------------------------------------------------------------+
//| SZ Mitigation                                                    |
//+------------------------------------------------------------------+
bool IsSZMitigatedAfterBoS(double zoneTop, int confirmationBar)
{
   if(zoneTop <= 0 || confirmationBar <= 0) return false;

   for(int i = confirmationBar - 1; i >= 1; i--)
   {
      double close = iClose(_Symbol, PERIOD_CURRENT, i);
      if(close > zoneTop) return true;
   }
   return false;
}

//+------------------------------------------------------------------+
//| Update DZ Status                                                 |
//+------------------------------------------------------------------+
void UpdateDZStatus()
{
   if(dzDrawTime == 0) return;

   if(!dzConfirmed)
   {
      double demandLow = 0, demandOpen = 0, demandClose = 0;
      datetime confirmationTime = 0;
      int breakingBar = FindBreakingCandleDZ(dzCandleHigh, dzDrawTime, demandLow, demandOpen, demandClose, confirmationTime);

      if(breakingBar >= 0)
      {
         dzConfirmed = true;
         dzConfirmationBar = breakingBar;
         dzCandleLow = demandLow;

         if(level1BreakTime > 0)
         {
            if(IsDemandCandleMitigated(dzCandleHigh, dzCandleLow, dzDrawTime, confirmationTime, level1BreakTime))
            {
               dzMitigated = true;
               if(ObjectFind(0, "DemandZone_Label") >= 0)
                  ObjectSetString(0, "DemandZone_Label", OBJPROP_TEXT, "DZ (mitigated)");
            }
         }
      }
   }

   if(dzConfirmed && !dzMitigated)
   {
      for(int i = dzConfirmationBar - 1; i >= 1; i--)
      {
         double close = iClose(_Symbol, PERIOD_CURRENT, i);
         if(close < dzBottomPrice)
         {
            dzMitigated = true;
            if(ObjectFind(0, "DemandZone_Label") >= 0)
               ObjectSetString(0, "DemandZone_Label", OBJPROP_TEXT, "DZ (mitigated)");
            break;
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Update SZ Status                                                 |
//+------------------------------------------------------------------+
void UpdateSZStatus()
{
   if(szDrawTime == 0) return;

   if(!szConfirmed)
   {
      double supplyHigh = 0, supplyOpen = 0, supplyClose = 0;
      datetime confirmationTime = 0;
      int breakingBar = FindBreakingCandleSZ(szCandleLow, szDrawTime, supplyHigh, supplyOpen, supplyClose, confirmationTime);

      if(breakingBar >= 0)
      {
         szConfirmed = true;
         szConfirmationBar = breakingBar;
         szCandleHigh = supplyHigh;

         if(level1BreakTime > 0)
         {
            if(IsSupplyCandleMitigated(szCandleHigh, szCandleLow, szDrawTime, level1BreakTime))
            {
               szMitigated = true;
               if(ObjectFind(0, "SupplyZone_Label") >= 0)
                  ObjectSetString(0, "SupplyZone_Label", OBJPROP_TEXT, "SZ (mitigated)");
            }
         }
      }
   }

   if(szConfirmed && !szMitigated)
   {
      for(int i = szConfirmationBar - 1; i >= 1; i--)
      {
         double close = iClose(_Symbol, PERIOD_CURRENT, i);
         if(close > szTopPrice)
         {
            szMitigated = true;
            if(ObjectFind(0, "SupplyZone_Label") >= 0)
               ObjectSetString(0, "SupplyZone_Label", OBJPROP_TEXT, "SZ (mitigated)");
            break;
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Update MB Status                                                 |
//+------------------------------------------------------------------+
bool IsMBMitigated(double zoneTop, double zoneBottom, datetime drawTime)
{
   if(zoneTop <= 0 || zoneBottom <= 0 || drawTime <= 0) return false;
   if(zoneTop <= zoneBottom) return false;

   int drawBar = iBarShift(_Symbol, PERIOD_CURRENT, drawTime);
   if(drawBar < 0) return false;

   for(int i = drawBar; i >= 1; i--)
   {
      double high = iHigh(_Symbol, PERIOD_CURRENT, i);
      double low = iLow(_Symbol, PERIOD_CURRENT, i);
      if(high >= zoneBottom && low <= zoneTop) return true;
   }
   return false;
}

void UpdateMBStatus()
{
   if(mbDrawTime == 0) return;

   if(!mbMitigated)
   {
      if(IsMBMitigated(mbTopPrice, mbBottomPrice, mbDrawTime))
      {
         mbMitigated = true;
         if(ObjectFind(0, "MB_Label") >= 0)
            ObjectSetString(0, "MB_Label", OBJPROP_TEXT, "MB (mitigated)");
      }
   }
}

//+------------------------------------------------------------------+
//| Find Mitigation Block                                            |
//+------------------------------------------------------------------+
void FindMitigationBlock(int preRetracementBar, int level2Bar,
                          datetime &mbStartTime, datetime &mbEndTime,
                          double &mbBottom, double &mbTop, double level1Price)
{
   mbStartTime = 0;
   mbEndTime = 0;
   mbBottom = 0;
   mbTop = 0;

   int scanCandles = BackwardCandlesToScanForMB;
   if(scanCandles <= 0) scanCandles = 20;

   int fromBar = preRetracementBar;
   int toBar = preRetracementBar + scanCandles;

   totalBars = Bars(_Symbol, PERIOD_CURRENT);
   if(toBar >= totalBars) toBar = totalBars - 1;

   if(trendDirection == 1)  // BULLISH
   {
      double closestClose = 0;
      int closestBar = -1;
      double smallestDistance = DBL_MAX;

      for(int i = fromBar; i <= toBar; i++)
      {
         double open = iOpen(_Symbol, PERIOD_CURRENT, i);
         double close = iClose(_Symbol, PERIOD_CURRENT, i);

         if(close > open && close < level1Price)
         {
            double distance = level1Price - close;
            if(distance < smallestDistance)
            {
               smallestDistance = distance;
               closestClose = close;
               closestBar = i;
            }
         }
      }

      if(closestBar >= 0)
      {
         mbStartTime = iTime(_Symbol, PERIOD_CURRENT, closestBar);
         mbEndTime = mbStartTime + PeriodSeconds(PERIOD_CURRENT);
         mbBottom = closestClose;
         mbTop = level1Price;
      }
   }
   else  // BEARISH
   {
      double closestClose = 0;
      int closestBar = -1;
      double smallestDistance = DBL_MAX;

      for(int i = fromBar; i <= toBar; i++)
      {
         double open = iOpen(_Symbol, PERIOD_CURRENT, i);
         double close = iClose(_Symbol, PERIOD_CURRENT, i);

         if(close < open && close > level1Price)
         {
            double distance = close - level1Price;
            if(distance < smallestDistance)
            {
               smallestDistance = distance;
               closestClose = close;
               closestBar = i;
            }
         }
      }

      if(closestBar >= 0)
      {
         mbStartTime = iTime(_Symbol, PERIOD_CURRENT, closestBar);
         mbEndTime = mbStartTime + PeriodSeconds(PERIOD_CURRENT);
         mbBottom = level1Price;
         mbTop = closestClose;
      }
   }
}

//+------------------------------------------------------------------+
//| PD Arrays (Bullish)                                              |
//+------------------------------------------------------------------+
void FindClosestPDArray(double level2Price, datetime level2Time, datetime referenceTime)
{
   int level2Bar = iBarShift(_Symbol, PERIOD_CURRENT, level2Time);
   if(level2Bar < 0) return;

   double pipSize = _Point;
   if(_Digits == 5 || _Digits == 3) pipSize = _Point * 10;
   double demandBuffer = SLBufferPips * pipSize;
   double fvgBuffer = SLFVGBufferPips * pipSize;

   int fvgBar = -1;
   double fvgSLPrice = 0;

   int demandBar = -1;
   double demandSLPrice = 0;
   double demandLow = 0;

   int maxCandles = MaxCandlesToScan;

   for(int i = level2Bar + 2; i <= level2Bar + 2 + maxCandles; i++)
   {
      if(i + 2 >= Bars(_Symbol, PERIOD_CURRENT)) continue;
      double high1 = iHigh(_Symbol, PERIOD_CURRENT, i + 2);
      double low3 = iLow(_Symbol, PERIOD_CURRENT, i);
      double low2 = iLow(_Symbol, PERIOD_CURRENT, i + 1);

      if(high1 < low3)
      {
         double fvgTop = low2;
         double fvgBottom = high1;
         if(fvgTop < fvgBottom) { double temp = fvgTop; fvgTop = fvgBottom; fvgBottom = temp; }
         if(fvgTop < level2Price && fvgBottom < level2Price)
         {
            fvgBar = i;
            fvgSLPrice = high1 - fvgBuffer;
            break;
         }
      }

      double low1 = iLow(_Symbol, PERIOD_CURRENT, i + 2);
      double high3 = iHigh(_Symbol, PERIOD_CURRENT, i);
      if(low1 > high3)
      {
         double fvgTop = low1;
         double fvgBottom = iLow(_Symbol, PERIOD_CURRENT, i + 1);
         if(fvgTop < fvgBottom) { double temp = fvgTop; fvgTop = fvgBottom; fvgBottom = temp; }
         if(fvgTop < level2Price && fvgBottom < level2Price)
         {
            fvgBar = i;
            fvgSLPrice = high1 - fvgBuffer;
            break;
         }
      }
   }

   for(int i = level2Bar + 1; i <= level2Bar + 1 + maxCandles; i++)
   {
      if(i >= Bars(_Symbol, PERIOD_CURRENT)) continue;
      double currOpen = iOpen(_Symbol, PERIOD_CURRENT, i);
      double currClose = iClose(_Symbol, PERIOD_CURRENT, i);
      double currLow = iLow(_Symbol, PERIOD_CURRENT, i);
      if(IsBearish(i) && currOpen < level2Price && currClose < level2Price)
      {
         demandBar = i;
         demandLow = currLow;
         demandSLPrice = demandLow - demandBuffer;
         break;
      }
   }

   if(fvgBar == -1 && demandBar == -1)
   {
      double fallbackSL = level2Price - demandBuffer;
      DrawStopLossLine(fallbackSL, referenceTime);
      return;
   }

   double slPrice = 0;
   if(fvgBar != -1 && demandBar != -1)
      slPrice = (fvgBar <= demandBar) ? fvgSLPrice : demandSLPrice;
   else if(fvgBar != -1)
      slPrice = fvgSLPrice;
   else if(demandBar != -1)
      slPrice = demandSLPrice;

   DrawStopLossLine(slPrice, referenceTime);
   currentSLPrice = slPrice;
}

//+------------------------------------------------------------------+
//| PD Arrays (Bearish)                                              |
//+------------------------------------------------------------------+
void FindClosestPDArraySZ(double level2Price, datetime level2Time, datetime referenceTime)
{
   int level2Bar = iBarShift(_Symbol, PERIOD_CURRENT, level2Time);
   if(level2Bar < 0) return;

   double pipSize = _Point;
   if(_Digits == 5 || _Digits == 3) pipSize = _Point * 10;
   double supplyBuffer = SLBufferPips * pipSize;
   double fvgBuffer = SLFVGBufferPips * pipSize;

   int fvgBar = -1;
   double fvgSLPrice = 0;

   int supplyBar = -1;
   double supplySLPrice = 0;
   double supplyHigh = 0;

   int maxCandles = MaxCandlesToScan;

   for(int i = level2Bar + 1; i <= level2Bar + 1 + maxCandles; i++)
   {
      if(i >= Bars(_Symbol, PERIOD_CURRENT)) continue;

      double currOpen = iOpen(_Symbol, PERIOD_CURRENT, i);
      double currClose = iClose(_Symbol, PERIOD_CURRENT, i);
      double currHigh = iHigh(_Symbol, PERIOD_CURRENT, i);

      if(IsBullish(i) && currOpen > level2Price && currClose > level2Price)
      {
         supplyBar = i;
         supplyHigh = currHigh;
         supplySLPrice = supplyHigh + supplyBuffer;
         break;
      }
   }

   for(int i = level2Bar + 2; i <= level2Bar + 2 + maxCandles; i++)
   {
      if(i + 2 >= Bars(_Symbol, PERIOD_CURRENT)) continue;

      double low1 = iLow(_Symbol, PERIOD_CURRENT, i + 2);
      double high3 = iHigh(_Symbol, PERIOD_CURRENT, i);
      double high2 = iHigh(_Symbol, PERIOD_CURRENT, i + 1);

      if(low1 > high3)
      {
         double fvgTop = low1;
         double fvgBottom = high2;
         if(fvgTop < fvgBottom) { double temp = fvgTop; fvgTop = fvgBottom; fvgBottom = temp; }

         if(fvgTop > level2Price && fvgBottom > level2Price)
         {
            fvgBar = i;
            fvgSLPrice = fvgTop + fvgBuffer;
            break;
         }
      }
   }

   if(fvgBar == -1)
   {
      for(int i = level2Bar + 1; i <= level2Bar + 1 + maxCandles; i++)
      {
         if(i + 1 >= Bars(_Symbol, PERIOD_CURRENT)) continue;

         double low1 = iLow(_Symbol, PERIOD_CURRENT, i);
         double high2 = iHigh(_Symbol, PERIOD_CURRENT, i + 1);

         if(low1 > high2)
         {
            double fvgTop = low1;
            double fvgBottom = high2;

            if(fvgTop > level2Price && fvgBottom > level2Price)
            {
               fvgBar = i;
               fvgSLPrice = fvgTop + fvgBuffer;
               break;
            }
         }
      }
   }

   if(supplyBar == -1 && fvgBar == -1)
   {
      double fallbackSL = level2Price + supplyBuffer;
      DrawStopLossLine(fallbackSL, referenceTime);
      currentSLPrice = fallbackSL;
      return;
   }

   double slPrice = 0;
   if(supplyBar != -1 && fvgBar != -1)
      slPrice = (supplyBar <= fvgBar) ? supplySLPrice : fvgSLPrice;
   else if(supplyBar != -1)
      slPrice = supplySLPrice;
   else if(fvgBar != -1)
      slPrice = fvgSLPrice;

   DrawStopLossLine(slPrice, referenceTime);
   currentSLPrice = slPrice;
}

//+------------------------------------------------------------------+
//| Ensure SL Price is Set                                           |
//+------------------------------------------------------------------+
void EnsureSLPriceIsSet()
{
   if(currentSLPrice > 0) return;
   if(dzBottomPrice <= 0 && szTopPrice <= 0) return;

   if(ObjectFind(0, "SL_Line") >= 0)
   {
      double slPrice = ObjectGetDouble(0, "SL_Line", OBJPROP_PRICE, 0);
      if(slPrice > 0)
      {
         currentSLPrice = slPrice;
         return;
      }
   }

   double pipSize = _Point;
   if(_Digits == 5 || _Digits == 3) pipSize = _Point * 10;
   double fallbackBuffer = SLBufferPips * pipSize;

   if(trendDirection == 1 && dzBottomPrice > 0)
      currentSLPrice = dzBottomPrice - fallbackBuffer;
   else if(trendDirection == -1 && szTopPrice > 0)
      currentSLPrice = szTopPrice + fallbackBuffer;
}

#endif // SBT_ZONES_MQH
//+------------------------------------------------------------------+