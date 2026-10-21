//+------------------------------------------------------------------+
//|                                                 SBT_Common.mqh   |
//|                                    Copyright 2026, sbt_trading   |
//|  Shared: colors, inputs, structs, enums, magic, trade object     |
//+------------------------------------------------------------------+
#ifndef SBT_COMMON_MQH
#define SBT_COMMON_MQH

#property strict

#include <Trade/Trade.mqh>

//--- Trade object (defined once, here)
CTrade trade;

//--- Colors
#define COLOR_LEVEL1 clrDodgerBlue
#define COLOR_LEVEL2 clrRed
#define COLOR_LEVEL3 clrGoldenrod
#define COLOR_MB     clrBlueViolet
#define COLOR_DZ     clrLimeGreen
#define COLOR_SZ     clrCrimson
#define COLOR_SL     clrRed
#define COLOR_ABCDE  clrGold

//--- Input Parameters
input int    TrendDirection                = 1;      // 1 = Bullish, -1 = Bearish
input int    SLBufferPips                  = 5;      // Stop Loss buffer in pips (Demand Candle)
input int    SLFVGBufferPips               = 10;     // Stop Loss buffer in pips for FVG
input int    MaxCandlesToScan              = 30;     // Maximum candles to scan for PD arrays
input int    BackwardCandlesToScanForMB    = 10;     // Number of candles to scan backward for MB
input double RiskPercent                   = 1.0;    // Risk percentage of equity
input double RiskRewardRatio               = 6.0;    // Risk to Reward ratio (1:6 for full TP)
input int    MagicNumber                   = 123456; // EA Magic Number for position identification
input double PartialProfitPercent          = 80.0;   // % of profit to book at Level 3
input bool   UseBreakeven                  = true;   // Enable Breakeven after partial profit
input int    MaxConcurrentPositions        = 5;      // Maximum positions allowed at once

input int    ZoneExtensionLeft             = 100;    // Candles to extend zones LEFT
input int    ZoneExtensionRight            = 100;    // Candles to extend zones RIGHT

input bool   ShowABCDEVisuals              = true;   // Draw ABCDE labels + trend lines

//--- PD Array Structure
struct PDArray
{
   string   type;
   double   top;
   double   bottom;
   datetime startTime;
   datetime endTime;
   bool     isValid;
};

#endif // SBT_COMMON_MQH
//+------------------------------------------------------------------+