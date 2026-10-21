//+------------------------------------------------------------------+
//|                                            SBT_Retracement.mqh   |
//|                                    Copyright 2026, sbt_trading   |
//|  Retracement rules (host Rules 1/2/3 + mother candle) and        |
//|  ABCDE retracement-rule checks (Rules 1/2/3 + mother candle).    |
//+------------------------------------------------------------------+
#ifndef SBT_RETRACEMENT_MQH
#define SBT_RETRACEMENT_MQH

#include "SBT_Trend.mqh"

//+------------------------------------------------------------------+
//| ABCDE retracement rule checks                                    |
//+------------------------------------------------------------------+
bool CheckBearishRetracementRulesABCDE(int &ruleUsed, double &triggerPrice)
{
   double currClose1 = iClose(_Symbol, PERIOD_CURRENT, 1);
   double currHigh1 = iHigh(_Symbol, PERIOD_CURRENT, 1);
   double currLow1 = iLow(_Symbol, PERIOD_CURRENT, 1);
   double prevHigh = iHigh(_Symbol, PERIOD_CURRENT, 2);
   double prevLow = iLow(_Symbol, PERIOD_CURRENT, 2);

   bool currBearish = IsBearish(1);
   bool prevBullish = IsBullish(2);

   if(currBearish && prevBullish && currLow1 <= prevLow && currClose1 <= prevLow)
   {
      ruleUsed = 1;
      triggerPrice = currHigh1;
      return true;
   }

   if(currBearish && IsBearish(2))
   {
      if(currClose1 < iLow(_Symbol, PERIOD_CURRENT, 2))
      {
         ruleUsed = 2;
         triggerPrice = currHigh1;
         return true;
      }
   }

   static bool bearMotherActive = false;
   static double bearMotherOpen = 0;
   static double bearMotherLow = 0;

   if(!bearMotherActive)
   {
      for(int i = 1; i <= 10; i++)
      {
         if(IsBearish(i))
         {
            bearMotherActive = true;
            bearMotherOpen = iOpen(_Symbol, PERIOD_CURRENT, i);
            bearMotherLow = iLow(_Symbol, PERIOD_CURRENT, i);
            break;
         }
      }
   }

   if(bearMotherActive)
   {
      double latestClose = iClose(_Symbol, PERIOD_CURRENT, 1);
      if(IsBullish(1) && latestClose > bearMotherOpen)
         bearMotherActive = false;
      else if(IsBearish(1) && latestClose < bearMotherLow)
      {
         ruleUsed = 3;
         triggerPrice = currHigh1;
         bearMotherActive = false;
         return true;
      }
   }

   return false;
}

bool CheckBullishRetracementRulesABCDE(int &ruleUsed, double &triggerPrice)
{
   double currClose1 = iClose(_Symbol, PERIOD_CURRENT, 1);
   double currHigh1 = iHigh(_Symbol, PERIOD_CURRENT, 1);
   double currLow1 = iLow(_Symbol, PERIOD_CURRENT, 1);
   double prevHigh = iHigh(_Symbol, PERIOD_CURRENT, 2);

   bool currBullish = IsBullish(1);
   bool prevBearish = IsBearish(2);

   if(currBullish && prevBearish && currHigh1 >= prevHigh && currClose1 >= prevHigh)
   {
      ruleUsed = 1;
      triggerPrice = currLow1;
      return true;
   }

   if(currBullish && IsBullish(2))
   {
      if(currClose1 > iHigh(_Symbol, PERIOD_CURRENT, 2))
      {
         ruleUsed = 2;
         triggerPrice = currLow1;
         return true;
      }
   }

   static bool bullMotherActive = false;
   static double bullMotherOpen = 0;
   static double bullMotherHigh = 0;

   if(!bullMotherActive)
   {
      for(int i = 1; i <= 10; i++)
      {
         if(IsBullish(i))
         {
            bullMotherActive = true;
            bullMotherOpen = iOpen(_Symbol, PERIOD_CURRENT, i);
            bullMotherHigh = iHigh(_Symbol, PERIOD_CURRENT, i);
            break;
         }
      }
   }

   if(bullMotherActive)
   {
      double latestClose = iClose(_Symbol, PERIOD_CURRENT, 1);
      if(IsBearish(1) && latestClose < bullMotherOpen)
         bullMotherActive = false;
      else if(IsBullish(1) && latestClose > bullMotherHigh)
      {
         ruleUsed = 3;
         triggerPrice = currLow1;
         bullMotherActive = false;
         return true;
      }
   }

   return false;
}

//+------------------------------------------------------------------+
//| Check Retracement Rules (Host - Rules 1 & 2 + Rule 3 mother)     |
//+------------------------------------------------------------------+
bool CheckRetracementRules(int &ruleUsed, double &triggerPrice)
{
   double currOpen1 = iOpen(_Symbol, PERIOD_CURRENT, 1);
   double currClose1 = iClose(_Symbol, PERIOD_CURRENT, 1);
   double currHigh1 = iHigh(_Symbol, PERIOD_CURRENT, 1);
   double currLow1 = iLow(_Symbol, PERIOD_CURRENT, 1);
   double prevOpen = iOpen(_Symbol, PERIOD_CURRENT, 2);
   double prevClose = iClose(_Symbol, PERIOD_CURRENT, 2);
   double prevHigh = iHigh(_Symbol, PERIOD_CURRENT, 2);
   double prevLow = iLow(_Symbol, PERIOD_CURRENT, 2);

   bool currBearish = IsBearish(1);
   bool currBullish = IsBullish(1);
   bool prevBullish = IsBullish(2);
   bool prevBearish = IsBearish(2);

   Print("========================================");
   Print("🔍 CHECKING RETRACEMENT RULES - START");
   Print("   Trend Direction: ", trendDirection == 1 ? "BULLISH" : "BEARISH");
   Print("   Mother Candle Active: ", motherCandleActive ? "YES" : "NO");
   Print("   Retracement Started: ", retracementStarted ? "YES" : "NO");
   Print("   Current Candle (Bar 1):");
   Print("      Time: ", TimeToString(iTime(_Symbol, PERIOD_CURRENT, 1)));
   Print("      Open: ", DoubleToString(currOpen1, _Digits));
   Print("      High: ", DoubleToString(currHigh1, _Digits));
   Print("      Low: ", DoubleToString(currLow1, _Digits));
   Print("      Close: ", DoubleToString(currClose1, _Digits));
   Print("      Type: ", currBullish ? "BULLISH" : (currBearish ? "BEARISH" : "DOJI"));
   Print("   Previous Candle (Bar 2):");
   Print("      Time: ", TimeToString(iTime(_Symbol, PERIOD_CURRENT, 2)));
   Print("      Open: ", DoubleToString(prevOpen, _Digits));
   Print("      High: ", DoubleToString(prevHigh, _Digits));
   Print("      Low: ", DoubleToString(prevLow, _Digits));
   Print("      Close: ", DoubleToString(prevClose, _Digits));
   Print("      Type: ", prevBullish ? "BULLISH" : (prevBearish ? "BEARISH" : "DOJI"));
   Print("========================================");

   // ========== PRIORITY LOCKING ==========
   if(motherCandleActive)
   {
      Print("🔒 MOTHER CANDLE ACTIVE - Locking Rules 1 & 2");
      Print("   Only checking Mother Candle conditions...");
      Print("========================================");

      if(trendDirection == 1)  // BULLISH - Mother Candle is bearish
      {
         double latestClose = iClose(_Symbol, PERIOD_CURRENT, 1);
         bool latestBullish = IsBullish(1);
         bool latestBearish = IsBearish(1);

         Print("📊 BULLISH TREND - Mother Candle (Bearish) Tracking:");
         Print("   Mother Open: ", DoubleToString(motherCandleOpen, _Digits));
         Print("   Mother Low: ", DoubleToString(motherCandleLow, _Digits));
         Print("   Latest Close: ", DoubleToString(latestClose, _Digits));
         Print("   Latest Bullish? ", latestBullish);
         Print("   Latest Bearish? ", latestBearish);
         Print("   Latest Close > Mother Open? ", latestClose > motherCandleOpen);
         Print("   Latest Close < Mother Low? ", latestClose < motherCandleLow);

         if(latestBullish && latestClose > motherCandleOpen)
         {
            Print("   ❌ Mother Candle CANCELLED - Bullish closed above mother open");
            motherCandleActive = false;
            Print("   🔓 Rules 1 & 2 UNLOCKED");
            Print("========================================");
            return false;
         }
         else if(latestBearish && latestClose < motherCandleLow)
         {
            ruleUsed = 3;
            triggerPrice = iHigh(_Symbol, PERIOD_CURRENT, 1);
            motherCandleActive = false;
            Print("   ✅ RULE 3 TRIGGERED! (Mother Candle)");
            Print("   Trigger Price (High): ", DoubleToString(triggerPrice, _Digits));
            Print("========================================");
            return true;
         }
         else
         {
            Print("   ⏳ Mother Candle still active - Waiting for trigger or cancel");
            Print("========================================");
            return false;
         }
      }
      else  // BEARISH - Mother Candle is bullish
      {
         double latestClose = iClose(_Symbol, PERIOD_CURRENT, 1);
         bool latestBullish = IsBullish(1);
         bool latestBearish = IsBearish(1);

         Print("📊 BEARISH TREND - Mother Candle (Bullish) Tracking:");
         Print("   Mother Open: ", DoubleToString(motherCandleOpen, _Digits));
         Print("   Mother High: ", DoubleToString(motherCandleHigh, _Digits));
         Print("   Latest Close: ", DoubleToString(latestClose, _Digits));
         Print("   Latest Bullish? ", latestBullish);
         Print("   Latest Bearish? ", latestBearish);
         Print("   Latest Close < Mother Open? ", latestClose < motherCandleOpen);
         Print("   Latest Close > Mother High? ", latestClose > motherCandleHigh);

         if(latestBearish && latestClose < motherCandleOpen)
         {
            Print("   ❌ Mother Candle CANCELLED - Bearish closed below mother open");
            motherCandleActive = false;
            Print("   🔓 Rules 1 & 2 UNLOCKED");
            Print("========================================");
            return false;
         }
         else if(latestBullish && latestClose > motherCandleHigh)
         {
            ruleUsed = 3;
            triggerPrice = iLow(_Symbol, PERIOD_CURRENT, 1);
            motherCandleActive = false;
            Print("   ✅ RULE 3 TRIGGERED! (Mother Candle)");
            Print("   Trigger Price (Low): ", DoubleToString(triggerPrice, _Digits));
            Print("========================================");
            return true;
         }
         else
         {
            Print("   ⏳ Mother Candle still active - Waiting for trigger or cancel");
            Print("========================================");
            return false;
         }
      }
   }

   // ========== NO MOTHER CANDLE ACTIVE - Check Rules 1 & 2 ==========
   Print("🔓 No Mother Candle Active - Checking Rules 1 & 2");
   Print("========================================");

   if(trendDirection == 1)  // BULLISH - look for bearish retracement
   {
      if(currBearish && prevBullish && currLow1 <= prevLow && currClose1 <= prevLow)
      {
         ruleUsed = 1;
         triggerPrice = currHigh1;
         Print("   ✅ RULE 1 TRIGGERED! (Bearish Engulfing)");
         return true;
      }

      if(currBearish && IsBearish(2))
      {
         if(currClose1 < iLow(_Symbol, PERIOD_CURRENT, 2))
         {
            ruleUsed = 2;
            triggerPrice = currHigh1;
            Print("   ✅ RULE 2 TRIGGERED! (Two Consecutive Bearish)");
            return true;
         }
      }

      if(!retracementStarted && !motherCandleActive)
      {
         for(int i = 1; i <= 10; i++)
         {
            if(IsBearish(i))
            {
               motherCandleActive = true;
               motherCandleOpen = iOpen(_Symbol, PERIOD_CURRENT, i);
               motherCandleLow = iLow(_Symbol, PERIOD_CURRENT, i);
               motherCandleTime = iTime(_Symbol, PERIOD_CURRENT, i);
               Print("   ✅ Mother Candle SET at Bar ", i);
               return false;
            }
         }
      }

      return false;
   }
   else  // BEARISH - look for bullish retracement
   {
      if(currBullish && prevBearish && currHigh1 >= prevHigh && currClose1 >= prevHigh)
      {
         ruleUsed = 1;
         triggerPrice = currLow1;
         return true;
      }

      if(currBullish && IsBullish(2))
      {
         if(currClose1 > iHigh(_Symbol, PERIOD_CURRENT, 2))
         {
            ruleUsed = 2;
            triggerPrice = currLow1;
            return true;
         }
      }

      if(!retracementStarted && !motherCandleActive)
      {
         for(int i = 1; i <= 10; i++)
         {
            if(IsBullish(i))
            {
               motherCandleActive = true;
               motherCandleOpen = iOpen(_Symbol, PERIOD_CURRENT, i);
               motherCandleHigh = iHigh(_Symbol, PERIOD_CURRENT, i);
               motherCandleTime = iTime(_Symbol, PERIOD_CURRENT, i);
               Print("   ✅ Mother Candle SET at Bar ", i);
               return false;
            }
         }
      }

      return false;
   }
}

#endif // SBT_RETRACEMENT_MQH
//+------------------------------------------------------------------+