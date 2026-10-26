//+------------------------------------------------------------------+
//|                                                 HTF_Trend.mqh    |
//|                                    Copyright 2026, sbt_trading   |
//|  Full HTF engine mirroring LTF logic on HTF_Period.              |
//+------------------------------------------------------------------+
#ifndef HTF_TREND_MQH
#define HTF_TREND_MQH

#include "SBT_State.mqh"
#include "HTF_Drawing.mqh"

//+------------------------------------------------------------------+
//| HTF Candle Helpers                                               |
//+------------------------------------------------------------------+
bool HTF_IsBearish(int shift) { return (iClose(_Symbol, HTF_Period, shift) < iOpen(_Symbol, HTF_Period, shift)); }
bool HTF_IsBullish(int shift) { return (iClose(_Symbol, HTF_Period, shift) > iOpen(_Symbol, HTF_Period, shift)); }

//+------------------------------------------------------------------+
//| HTF Range Helpers                                                |
//+------------------------------------------------------------------+
double HTF_FindLowestLowBetween(datetime startTime, datetime endTime)
{
   if(startTime <= 0 || endTime <= 0) return 0;
   int startBar = iBarShift(_Symbol, HTF_Period, startTime);
   int endBar   = iBarShift(_Symbol, HTF_Period, endTime);
   if(startBar < 0 || endBar < 0) return 0;
   int from = MathMax(startBar, endBar);
   int to   = MathMin(startBar, endBar);
   double lowestLow = DBL_MAX;
   for(int i = from; i >= to; i--)
   {
      double l = iLow(_Symbol, HTF_Period, i);
      if(l < lowestLow) lowestLow = l;
   }
   return (lowestLow == DBL_MAX) ? 0 : lowestLow;
}

double HTF_FindHighestHighBetween(datetime startTime, datetime endTime)
{
   if(startTime <= 0 || endTime <= 0) return 0;
   int startBar = iBarShift(_Symbol, HTF_Period, startTime);
   int endBar   = iBarShift(_Symbol, HTF_Period, endTime);
   if(startBar < 0 || endBar < 0) return 0;
   int from = MathMax(startBar, endBar);
   int to   = MathMin(startBar, endBar);
   double highestHigh = -DBL_MAX;
   for(int i = from; i >= to; i--)
   {
      double h = iHigh(_Symbol, HTF_Period, i);
      if(h > highestHigh) highestHigh = h;
   }
   return (highestHigh == -DBL_MAX) ? 0 : highestHigh;
}

datetime HTF_FindTimeOfLowestLow(datetime startTime, datetime endTime)
{
   if(startTime <= 0 || endTime <= 0) return 0;
   int startBar = iBarShift(_Symbol, HTF_Period, startTime);
   int endBar   = iBarShift(_Symbol, HTF_Period, endTime);
   if(startBar < 0 || endBar < 0) return 0;
   int from = MathMax(startBar, endBar);
   int to   = MathMin(startBar, endBar);
   double lowestLow = DBL_MAX;
   int lowestBar = -1;
   for(int i = from; i >= to; i--)
   {
      double l = iLow(_Symbol, HTF_Period, i);
      if(l < lowestLow) { lowestLow = l; lowestBar = i; }
   }
   if(lowestBar < 0) return 0;
   return iTime(_Symbol, HTF_Period, lowestBar);
}

datetime HTF_FindTimeOfHighestHigh(datetime startTime, datetime endTime)
{
   if(startTime <= 0 || endTime <= 0) return 0;
   int startBar = iBarShift(_Symbol, HTF_Period, startTime);
   int endBar   = iBarShift(_Symbol, HTF_Period, endTime);
   if(startBar < 0 || endBar < 0) return 0;
   int from = MathMax(startBar, endBar);
   int to   = MathMin(startBar, endBar);
   double highestHigh = -DBL_MAX;
   int highestBar = -1;
   for(int i = from; i >= to; i--)
   {
      double h = iHigh(_Symbol, HTF_Period, i);
      if(h > highestHigh) { highestHigh = h; highestBar = i; }
   }
   if(highestBar < 0) return 0;
   return iTime(_Symbol, HTF_Period, highestBar);
}

void HTF_DetectTrend()
{
   if(htfForceFlipped) return;
   if(htfBullishEstablished || htfBearishEstablished) return;
   
   htfTotalBars = Bars(_Symbol, HTF_Period);
   if(htfTotalBars < 50) return;
   
   int shift = 50;
   double pastHigh = iHigh(_Symbol, HTF_Period, shift);
   double pastLow  = iLow(_Symbol, HTF_Period, shift);
   double currPrice = iClose(_Symbol, HTF_Period, 1);
   
   if(currPrice > pastHigh)
   {
      htfTrendDirection = 1;
      htfBullishEstablished = true;
      htfBearishEstablished = false;
      htfHighestHighSinceTrendStart = iHigh(_Symbol, HTF_Period, 1);
      htfHighestHighSinceTrendStart_Time = iTime(_Symbol, HTF_Period, 1);
      Print("✅ HTF BULLISH (Price > 50-bar High: ", pastHigh, ")");
   }
   else if(currPrice < pastLow)
   {
      htfTrendDirection = -1;
      htfBearishEstablished = true;
      htfBullishEstablished = false;
      htfLowestLowSinceTrendStart = iLow(_Symbol, HTF_Period, 1);
      htfLowestLowSinceTrendStart_Time = iTime(_Symbol, HTF_Period, 1);
      Print("✅ HTF BEARISH (Price < 50-bar Low: ", pastLow, ")");
   }
   else
   {
      htfTrendDirection = 0;
      Print("⏸️ HTF SIDEWAYS (Price inside 50-bar range)");
   }
}
//+------------------------------------------------------------------+
//| HTF Retracement Rules (Exact Mirror of LTF)                      |
//+------------------------------------------------------------------+
bool HTF_CheckRetracementRules(int &ruleUsed, double &triggerPrice)
{
   double currOpen1  = iOpen(_Symbol, HTF_Period, 1);
   double currClose1 = iClose(_Symbol, HTF_Period, 1);
   double currHigh1  = iHigh(_Symbol, HTF_Period, 1);
   double currLow1   = iLow(_Symbol, HTF_Period, 1);
   double prevOpen   = iOpen(_Symbol, HTF_Period, 2);
   double prevClose  = iClose(_Symbol, HTF_Period, 2);
   double prevHigh   = iHigh(_Symbol, HTF_Period, 2);
   double prevLow    = iLow(_Symbol, HTF_Period, 2);
   
   bool currBearish = HTF_IsBearish(1);
   bool currBullish = HTF_IsBullish(1);
   bool prevBullish = HTF_IsBullish(2);
   bool prevBearish = HTF_IsBearish(2);

   // 1. MOTHER CANDLE LOGIC (Rules 1 & 2 fall through if this doesn't trigger)
   if(htfMotherCandleActive)
   {
      int motherBar = iBarShift(_Symbol, HTF_Period, htfMotherCandleTime, false);
      if(motherBar < 1) motherBar = 1;

      if(htfTrendDirection == 1)  // BULLISH
      {
         bool invalidated = false;
         bool triggered = false;
         
         for(int i = 1; i <= motherBar; i++)
         {
            double cOpen = iOpen(_Symbol, HTF_Period, i);
            double cClose = iClose(_Symbol, HTF_Period, i);
            
            if(cClose > cOpen && cClose > htfMotherCandleOpen)
            {
               invalidated = true;
               Print("   ❌ HTF Mother Candle CANCELLED - Bullish closed above Open");
               break;
            }
            
            if(cClose < cOpen && cClose < htfMotherCandleLow)
            {
               triggered = true;
            }
         }
         
         if(invalidated)
         {
            htfMotherCandleActive = false;
            if((ENUM_TIMEFRAMES)Period() == HTF_Period) 
            {
               ObjectDelete(0, "HTF_MotherCandle_Box");
               ObjectDelete(0, "HTF_MotherCandle_Label");
            }
            // Do NOT return — let Rules 1 & 2 run
         }
         else if(triggered)
         {
            ruleUsed = 3;
            triggerPrice = currHigh1;
            htfMotherCandleActive = false;
            if((ENUM_TIMEFRAMES)Period() == HTF_Period) 
            {
               ObjectDelete(0, "HTF_MotherCandle_Box");
               ObjectDelete(0, "HTF_MotherCandle_Label");
            }
            Print("   ✅ HTF RULE 3 TRIGGERED! (Mother Candle)");
            return true;
         }
      }
      else  // BEARISH
      {
         bool invalidated = false;
         bool triggered = false;
         
         for(int i = 1; i <= motherBar; i++)
         {
            double cOpen = iOpen(_Symbol, HTF_Period, i);
            double cClose = iClose(_Symbol, HTF_Period, i);
            
            if(cClose < cOpen && cClose < htfMotherCandleOpen)
            {
               invalidated = true;
               Print("   ❌ HTF Mother Candle CANCELLED - Bearish closed below Open");
               break;
            }
            
            if(cClose > cOpen && cClose > htfMotherCandleHigh)
            {
               triggered = true;
            }
         }
         
         if(invalidated)
         {
            htfMotherCandleActive = false;
            if((ENUM_TIMEFRAMES)Period() == HTF_Period) 
            {
               ObjectDelete(0, "HTF_MotherCandle_Box");
               ObjectDelete(0, "HTF_MotherCandle_Label");
            }
            // Do NOT return — let Rules 1 & 2 run
         }
         else if(triggered)
         {
            ruleUsed = 3;
            triggerPrice = currLow1;
            htfMotherCandleActive = false;
            if((ENUM_TIMEFRAMES)Period() == HTF_Period) 
            {
               ObjectDelete(0, "HTF_MotherCandle_Box");
               ObjectDelete(0, "HTF_MotherCandle_Label");
            }
            Print("   ✅ HTF RULE 3 TRIGGERED! (Mother Candle)");
            return true;
         }
      }
   }

   // 2. RULES 1 & 2 (LTF-Equivalent)
   if(htfTrendDirection == 1)  // BULLISH
   {
      if(currBearish && prevBullish && currLow1 <= prevLow && currClose1 <= prevLow)
      {
         ruleUsed = 1; triggerPrice = currHigh1; return true;
      }
      if(currBearish && HTF_IsBearish(2) && currClose1 < iLow(_Symbol, HTF_Period, 2))
      {
         ruleUsed = 2; triggerPrice = currHigh1; return true;
      }
      
      // 3. NEW MOTHER CANDLE DETECTION
      if(!htfRetracementStarted && !htfMotherCandleActive)
      {
         double highestOpen = -DBL_MAX;
         int bestMotherBar = -1;
         
         for(int i = 1; i <= 10; i++)
         {
            if(HTF_IsBearish(i))
            {
               double open = iOpen(_Symbol, HTF_Period, i);
               if(open > highestOpen)
               {
                  highestOpen = open;
                  bestMotherBar = i;
               }
            }
         }
         
         if(bestMotherBar > 0)
         {
            htfMotherCandleActive = true;
            htfMotherCandleOpen = iOpen(_Symbol, HTF_Period, bestMotherBar);
            htfMotherCandleLow = iLow(_Symbol, HTF_Period, bestMotherBar);
            htfMotherCandleTime = iTime(_Symbol, HTF_Period, bestMotherBar);
            
            if((ENUM_TIMEFRAMES)Period() == HTF_Period)
               HTF_DrawMotherCandleBox(htfMotherCandleTime, htfMotherCandleOpen, htfMotherCandleLow, "Bearish Mother");
               
            Print("   ✅ HTF Mother Candle SET (Bearish) at Bar ", bestMotherBar);
            return false;
         }
      }
   }
   else  // BEARISH
   {
      if(currBullish && prevBearish && currHigh1 >= prevHigh && currClose1 >= prevHigh)
      {
         ruleUsed = 1; triggerPrice = currLow1; return true;
      }
      if(currBullish && HTF_IsBullish(2) && currClose1 > iHigh(_Symbol, HTF_Period, 2))
      {
         ruleUsed = 2; triggerPrice = currLow1; return true;
      }
      
      // 3. NEW MOTHER CANDLE DETECTION
      if(!htfRetracementStarted && !htfMotherCandleActive)
      {
         double lowestOpen = DBL_MAX;
         int bestMotherBar = -1;
         
         for(int i = 1; i <= 10; i++)
         {
            if(HTF_IsBullish(i))
            {
               double open = iOpen(_Symbol, HTF_Period, i);
               if(open < lowestOpen)
               {
                  lowestOpen = open;
                  bestMotherBar = i;
               }
            }
         }
         
         if(bestMotherBar > 0)
         {
            htfMotherCandleActive = true;
            htfMotherCandleOpen = iOpen(_Symbol, HTF_Period, bestMotherBar);
            htfMotherCandleHigh = iHigh(_Symbol, HTF_Period, bestMotherBar);
            htfMotherCandleTime = iTime(_Symbol, HTF_Period, bestMotherBar);
            
            if((ENUM_TIMEFRAMES)Period() == HTF_Period)
               HTF_DrawMotherCandleBox(htfMotherCandleTime, htfMotherCandleOpen, htfMotherCandleHigh, "Bullish Mother");
               
            Print("   ✅ HTF Mother Candle SET (Bullish) at Bar ", bestMotherBar);
            return false;
         }
      }
   }
   
   return false;
}

//+------------------------------------------------------------------+
//| HTF ABCDE Update (Exact Mirror of LTF UpdateABCDE)               |
//+------------------------------------------------------------------+
void HTF_UpdateABCDE(bool ruleFired, int ruleUsed, double triggerPrice)
{

   Print("🔍 HTF_ABCDE DEBUG | Wave=", htfAbcdeWave, 
      " | Active=", htfAbcdeActive, 
      " | RetStarted=", htfRetracementStarted,
      " | RefLow=", htfReferenceLowForInvalidation,
      " | RefHigh=", htfReferenceHighForInvalidation,
      " | MotherActive=", htfMotherCandleActive,
      " | ChoCh=", htfCurrentChochLevel,
      " | 0=", htfAbcde0, " | A=", htfAbcdeA,
      " | A_BodyBroken=", htfAbcdeA_BodyBroken,
      " | TrendDir=", htfTrendDirection);
      
   double bodyClose1 = iClose(_Symbol, HTF_Period, 1);
   datetime barTime1 = iTime(_Symbol, HTF_Period, 1);
   
     if(htfAbcdeActive)
   {
      if(htfAbcdeWave >= 3 && htfAbcdeB > 0)
      {
         if(htfTrendDirection == 1 && bodyClose1 > htfAbcdeB) 
         { 
            htfAbcdeActive = false; 
            htfAbcdeWave = 0; 
            htfAbcdeRetraceRuleCount = 0;
            htfAbcde0 = 0; htfAbcdeA = 0; htfAbcdeB = 0; htfAbcdeC = 0; htfAbcdeD = 0;
            return; 
         }
         if(htfTrendDirection == -1 && bodyClose1 < htfAbcdeB) 
         { 
            htfAbcdeActive = false; 
            htfAbcdeWave = 0; 
            htfAbcdeRetraceRuleCount = 0;
            htfAbcde0 = 0; htfAbcdeA = 0; htfAbcdeB = 0; htfAbcdeC = 0; htfAbcdeD = 0;
            return; 
         }
      }
      
      if(htfAbcdeWave == 1 && htfAbcde0 > 0)
      {
         if(htfTrendDirection == 1 && bodyClose1 > htfAbcde0) 
         { 
            htfAbcdeActive = false; 
            htfAbcdeWave = 0; 
            htfAbcdeRetraceRuleCount = 0;
            htfAbcde0 = 0; htfAbcdeA = 0; htfAbcdeB = 0; htfAbcdeC = 0; htfAbcdeD = 0;
            return; 
         }
         if(htfTrendDirection == -1 && bodyClose1 < htfAbcde0) 
         { 
            htfAbcdeActive = false; 
            htfAbcdeWave = 0; 
            htfAbcdeRetraceRuleCount = 0;
            htfAbcde0 = 0; htfAbcdeA = 0; htfAbcdeB = 0; htfAbcdeC = 0; htfAbcdeD = 0;
            return; 
         }
      }
   }
   // 2. CHECK FOR WAVE E (5-WAVE COMPLETION)
   if(htfAbcdeActive && htfAbcdeWave == 3)
   {
      bool eConfirmed = false;
      
      if(htfTrendDirection == 1 && bodyClose1 < htfAbcdeC)
         eConfirmed = true;
      else if(htfTrendDirection == -1 && bodyClose1 > htfAbcdeC)
         eConfirmed = true;
      
      if(eConfirmed)
      {
         if(htfTrendDirection == 1)
         {
            htfAbcdeD = HTF_FindHighestHighBetween(htfAbcdeC_Time, barTime1);
            htfAbcdeD_Time = HTF_FindTimeOfHighestHigh(htfAbcdeC_Time, barTime1);
         }
         else
         {
            htfAbcdeD = HTF_FindLowestLowBetween(htfAbcdeC_Time, barTime1);
            htfAbcdeD_Time = HTF_FindTimeOfLowestLow(htfAbcdeC_Time, barTime1);
         }
         
         if(htfAbcdeD > 0 && htfAbcdeD_Time > 0)
         {
            htfAbcdeWave = 5;
         }
         return;
      }
   }
   
   // 3. CHECK FOR WAVE B (A_BodyBroken)
   if(htfAbcdeActive && htfAbcdeWave == 1 && !htfAbcdeA_BodyBroken)
   {
      if(htfTrendDirection == 1 && bodyClose1 < htfAbcdeA) htfAbcdeA_BodyBroken = true;
      else if(htfTrendDirection == -1 && bodyClose1 > htfAbcdeA) htfAbcdeA_BodyBroken = true;
   }
   
   // 4. START NEW ABCDE IF RULE FIRES
   if(!ruleFired) return;
   
   if(htfAbcdeRetraceRuleCount == 0 && !htfAbcdeActive)
   {
      if(htfTrendDirection == 1)
      {
         htfAbcde0 = htfHighestHighSinceTrendStart;
         htfAbcde0_Time = htfHighestHighSinceTrendStart_Time;
         if(htfAbcde0_Time <= 0) return;
         htfAbcdeA = HTF_FindLowestLowBetween(htfAbcde0_Time, barTime1);
         htfAbcdeA_Time = HTF_FindTimeOfLowestLow(htfAbcde0_Time, barTime1);
      }
      else
      {
         htfAbcde0 = htfLowestLowSinceTrendStart;
         htfAbcde0_Time = htfLowestLowSinceTrendStart_Time;
         if(htfAbcde0_Time <= 0) return;
         htfAbcdeA = HTF_FindHighestHighBetween(htfAbcde0_Time, barTime1);
         htfAbcdeA_Time = HTF_FindTimeOfHighestHigh(htfAbcde0_Time, barTime1);
      }
      
      if(htfAbcdeA > 0 && htfAbcdeA_Time > 0)
      {
         htfAbcdeActive = true;
         htfAbcdeWave = 1;
         htfAbcdeRetraceRuleCount = 1;
         htfAbcdeA_BodyBroken = false;
      }
   }
   else if(htfAbcdeRetraceRuleCount == 1 && htfAbcdeActive && htfAbcdeWave == 1 && htfAbcdeA_BodyBroken)
   {
      htfAbcdeRetraceRuleCount = 2;
      
      if(htfTrendDirection == 1)
      {
         htfAbcdeC = HTF_FindLowestLowBetween(htfAbcdeA_Time, barTime1);
         htfAbcdeC_Time = HTF_FindTimeOfLowestLow(htfAbcdeA_Time, barTime1);
         
         if(htfAbcdeC_Time > 0)
         {
            htfAbcdeB = HTF_FindHighestHighBetween(htfAbcdeA_Time, htfAbcdeC_Time);
            htfAbcdeB_Time = HTF_FindTimeOfHighestHigh(htfAbcdeA_Time, htfAbcdeC_Time);
         }
         
         if(htfAbcdeB >= htfAbcde0) { htfAbcdeActive = false; return; }
         if(htfAbcdeC >= htfAbcdeA) { htfAbcdeActive = false; return; }
      }
      else
      {
         htfAbcdeC = HTF_FindHighestHighBetween(htfAbcdeA_Time, barTime1);
         htfAbcdeC_Time = HTF_FindTimeOfHighestHigh(htfAbcdeA_Time, barTime1);
         
         if(htfAbcdeC_Time > 0)
         {
            htfAbcdeB = HTF_FindLowestLowBetween(htfAbcdeA_Time, htfAbcdeC_Time);
            htfAbcdeB_Time = HTF_FindTimeOfLowestLow(htfAbcdeA_Time, htfAbcdeC_Time);
         }
         
         if(htfAbcdeB <= htfAbcde0) { htfAbcdeActive = false; return; }
         if(htfAbcdeC <= htfAbcdeA) { htfAbcdeActive = false; return; }
      }
      
      if(htfAbcdeB > 0 && htfAbcdeC > 0 && htfAbcdeB_Time > 0 && htfAbcdeC_Time > 0)
      {
         htfAbcdeWave = 3;
      }
      else
      {
         htfAbcdeActive = false;
      }
   }
}

//+------------------------------------------------------------------+
//| HTF Master Update (called on new HTF bar)                        |
//+------------------------------------------------------------------+
void UpdateHTFTrend()
{
   datetime htfBarTime = iTime(_Symbol, HTF_Period, 0);
   static datetime lastHTFBar = 0;
   if(htfBarTime == lastHTFBar) return;
   lastHTFBar = htfBarTime;

   htfForceFlipped = false;
   htfTotalBars = Bars(_Symbol, HTF_Period);
   
   if(htfTotalBars < 50) { htfTrendDirection = 0; return; }

   // ==========================================================
   // 1. SIMPLE INITIAL TREND DETECTION (50 Candles Back)
   // ==========================================================
   if(!htfBullishEstablished && !htfBearishEstablished)
   {
      int shift = 50;
      double pastHigh = iHigh(_Symbol, HTF_Period, shift);
      double pastLow  = iLow(_Symbol, HTF_Period, shift);
      double currPrice = iClose(_Symbol, HTF_Period, 1);
      
      if(currPrice > pastHigh)
      {
         htfTrendDirection = 1;
         htfBullishEstablished = true;
         htfBearishEstablished = false;
         htfHighestHighSinceTrendStart = currPrice;
         htfHighestHighSinceTrendStart_Time = iTime(_Symbol, HTF_Period, 1);
         Print("✅ HTF BULLISH (Price > 50-bar High: ", pastHigh, ")");
      }
      else if(currPrice < pastLow)
      {
         htfTrendDirection = -1;
         htfBearishEstablished = true;
         htfBullishEstablished = false;
         htfLowestLowSinceTrendStart = currPrice;
         htfLowestLowSinceTrendStart_Time = iTime(_Symbol, HTF_Period, 1);
         Print("✅ HTF BEARISH (Price < 50-bar Low: ", pastLow, ")");
      }
      else
      {
         htfTrendDirection = 0;
         Print("⏸️ HTF SIDEWAYS (Price inside 50-bar range)");
      }
   }

   // ==========================================================
   // 2. UPDATE HH/LL FIRST (Before Anything Else)
   // This ensures htfLowestLow/HighestHigh are always current
   // ==========================================================
   if(htfTrendDirection == 1)
   {
      double currHigh = iHigh(_Symbol, HTF_Period, 1);
      if(currHigh > htfHighestHighSinceTrendStart)
      {
         htfHighestHighSinceTrendStart = currHigh;
         htfHighestHighSinceTrendStart_Time = iTime(_Symbol, HTF_Period, 1);
      }
   }
   else if(htfTrendDirection == -1)
   {
      double currLow = iLow(_Symbol, HTF_Period, 1);
      if(currLow < htfLowestLowSinceTrendStart)
      {
         htfLowestLowSinceTrendStart = currLow;
         htfLowestLowSinceTrendStart_Time = iTime(_Symbol, HTF_Period, 1);
      }
   }

   // ==========================================================
   // 3. TREND TRACKING (BoS, ABCDE, ChoCh)
   // ==========================================================
   if(htfBullishEstablished || htfBearishEstablished)
   {
      int ruleUsed = 0;
      double trigPrice = 0;
      bool ruleFired = false;
      
      // 3.1. BoS invalidation
      if(htfRetracementStarted)
      {
         double currClose = iClose(_Symbol, HTF_Period, 1);
         datetime currBarTime = iTime(_Symbol, HTF_Period, 1);
         
         bool invalidated = false;
         if(htfTrendDirection == 1)
            invalidated = (currClose > htfReferenceHighForInvalidation);
         else
            invalidated = (currClose < htfReferenceLowForInvalidation);
         
         if(invalidated)
         {
            Print("📊 HTF BoS DETECTED | Close: ", currClose);
            
            double l1Price = (htfTrendDirection == 1) ? htfReferenceHighForInvalidation : htfReferenceLowForInvalidation;
            datetime l1Time = htfRetracementStartTime;
            
            if((ENUM_TIMEFRAMES)Period() == HTF_Period)
               HTF_DrawLevel1Line(l1Price, l1Time);
            
            int fromBar = MathMin(iBarShift(_Symbol, HTF_Period, htfRetracementStartTime), iBarShift(_Symbol, HTF_Period, currBarTime));
            int toBar = MathMax(iBarShift(_Symbol, HTF_Period, htfRetracementStartTime), iBarShift(_Symbol, HTF_Period, currBarTime));
            
            double l2Price = 0;
            datetime l2Time = 0;
            
            if(htfTrendDirection == 1)
            {
               double lowestLow = DBL_MAX;
               for(int i = fromBar; i <= toBar; i++)
               {
                  double low = iLow(_Symbol, HTF_Period, i);
                  if(low < lowestLow) { lowestLow = low; l2Time = iTime(_Symbol, HTF_Period, i); }
               }
               l2Price = lowestLow;
            }
            else
            {
               double highestHigh = -DBL_MAX;
               for(int i = fromBar; i <= toBar; i++)
               {
                  double high = iHigh(_Symbol, HTF_Period, i);
                  if(high > highestHigh) { highestHigh = high; l2Time = iTime(_Symbol, HTF_Period, i); }
               }
               l2Price = highestHigh;
            }
            
            htfCurrentChochLevel = l2Price;
            htfLevel2Price = l2Price;
            
            if(htfAbcdeWave == 5)
               htfPendingChochOrigin = "ABCDE 5-Wave";
            else
               htfPendingChochOrigin = "Normal";
            
            if((ENUM_TIMEFRAMES)Period() == HTF_Period)
            {
               int level2BarNumber = 0;
               HTF_DrawLevel2Line(l2Price, l2Time, currBarTime, level2BarNumber);
            }
            
            htfRetracementStarted = false;
            htfMotherCandleActive = false;
         }
      }
      
      // 3.2. STALE RETRACEMENT & INVALID REFERENCE RESET
      if(htfRetracementStarted)
      {
         bool forceReset = false;
         
         if(htfTrendDirection == 1 && htfReferenceHighForInvalidation <= 0) forceReset = true;
         if(htfTrendDirection == -1 && htfReferenceLowForInvalidation <= 0) forceReset = true;
         
         int barsSinceStart = iBarShift(_Symbol, HTF_Period, htfRetracementStartTime);
         if(barsSinceStart > 50) forceReset = true;
         
         if(forceReset)
         {
            Print("⚠️ HTF Retracement Reset. RefLow=", htfReferenceLowForInvalidation, " RefHigh=", htfReferenceHighForInvalidation);
            htfRetracementStarted = false;
            htfMotherCandleActive = false;
            htfReferenceHighForInvalidation = 0;
            htfReferenceLowForInvalidation = 0;
            ObjectDelete(0, "HTF_MotherCandle_Box");
            ObjectDelete(0, "HTF_MotherCandle_Label");
         }
      }
      
      // 3.3. Look for retracement
      if(!htfRetracementStarted)
      {
         ruleFired = HTF_CheckRetracementRules(ruleUsed, trigPrice);
         
         if(ruleFired)
         {
            if(htfTrendDirection == 1)
            {
               htfReferenceHighForInvalidation = MathMax(trigPrice, iHigh(_Symbol, HTF_Period, 1));
            }
            else
            {
               htfReferenceLowForInvalidation = MathMin(trigPrice, iLow(_Symbol, HTF_Period, 1));
            }
            
            htfRetracementStarted = true;
            htfRetracementStartTime = iTime(_Symbol, HTF_Period, 1);
            htfRetracementRuleUsed = ruleUsed;
            
            if((ENUM_TIMEFRAMES)Period() == HTF_Period)
               HTF_DrawLevel3Line(trigPrice, htfRetracementStartTime, iTime(_Symbol, HTF_Period, 1));
         }
      }
      
      // 3.4. ABCDE Update
      HTF_UpdateABCDE(ruleFired, ruleUsed, trigPrice);
      
      // 3.5. FORCE 5-WAVE FLIP IF HTF COMPLETES WAVE 5
      if(htfAbcdeWave == 5)
      {
         Print("🎯 HTF 5-Wave Completed. Forcing HTF Trend Flip.");
         htfForceFlipped = true;
         
         htfLastSwitchReason = "ABCDE 5-Wave";
         htfLastSwitchTime = iTime(_Symbol, HTF_Period, 1);
         
         if(htfTrendDirection == 1) // Bullish → Bearish
         {
            htfTrendDirection = -1;
            htfBullishEstablished = false;
            htfHighestHighSinceTrendStart = 0;
            htfHighestHighSinceTrendStart_Time = 0;
            htfBearishEstablished = true;
            htfLowestLowSinceTrendStart = iClose(_Symbol, HTF_Period, 1);
            htfLowestLowSinceTrendStart_Time = iTime(_Symbol, HTF_Period, 1);
         }
         else // Bearish → Bullish
         {
            htfTrendDirection = 1;
            htfBearishEstablished = false;
            htfLowestLowSinceTrendStart = 0;
            htfLowestLowSinceTrendStart_Time = 0;
            htfBullishEstablished = true;
            htfHighestHighSinceTrendStart = iClose(_Symbol, HTF_Period, 1);
            htfHighestHighSinceTrendStart_Time = iTime(_Symbol, HTF_Period, 1);
         }
         
         Print("   Flipped to: ", htfTrendDirection == 1 ? "BULLISH" : "BEARISH");
         
         htfAbcdeWave = 0;
         htfAbcdeActive = false;
         htfCurrentChochLevel = 0;
         htfLevel2Price = 0;
         htfMotherCandleActive = false;
         ObjectDelete(0, "HTF_MotherCandle_Box");
         ObjectDelete(0, "HTF_MotherCandle_Label");
      }
      
      // 3.6. ChoCh Confirmation + Stuck Recovery
      if(htfCurrentChochLevel > 0)
      {
         double currentClose = iClose(_Symbol, HTF_Period, 1);
         double previousClose = iClose(_Symbol, HTF_Period, 2);
         
         bool chochFired = false;
         
         if(htfTrendDirection == 1 && currentClose < htfCurrentChochLevel && previousClose < htfCurrentChochLevel)
         {
            Print("🎯 HTF CHOCH (Bullish → Bearish) at ", htfCurrentChochLevel);
            
            htfLastSwitchReason = (htfPendingChochOrigin == "ABCDE 5-Wave") ? "ABCDE 5-Wave" : "HTF ChoCh/MSS";
            htfLastSwitchTime = iTime(_Symbol, HTF_Period, 1);
            
            if((ENUM_TIMEFRAMES)Period() == HTF_Period)
               HTF_DrawChochConfirmation(htfCurrentChochLevel, iTime(_Symbol, HTF_Period, 1));
               
            htfTrendDirection = -1;
            htfBullishEstablished = false;
            htfHighestHighSinceTrendStart = 0;
            htfHighestHighSinceTrendStart_Time = 0;
            htfBearishEstablished = true;
            htfLowestLowSinceTrendStart = currentClose;
            htfLowestLowSinceTrendStart_Time = iTime(_Symbol, HTF_Period, 1);
            chochFired = true;
         }
         else if(htfTrendDirection == -1 && currentClose > htfCurrentChochLevel && previousClose > htfCurrentChochLevel)
         {
            Print("🎯 HTF CHOCH (Bearish → Bullish) at ", htfCurrentChochLevel);
            
            htfLastSwitchReason = (htfPendingChochOrigin == "ABCDE 5-Wave") ? "ABCDE 5-Wave" : "HTF ChoCh/MSS";
            htfLastSwitchTime = iTime(_Symbol, HTF_Period, 1);
            
            if((ENUM_TIMEFRAMES)Period() == HTF_Period)
               HTF_DrawChochConfirmation(htfCurrentChochLevel, iTime(_Symbol, HTF_Period, 1));
               
            htfTrendDirection = 1;
            htfBearishEstablished = false;
            htfLowestLowSinceTrendStart = 0;
            htfLowestLowSinceTrendStart_Time = 0;
            htfBullishEstablished = true;
            htfHighestHighSinceTrendStart = currentClose;
            htfHighestHighSinceTrendStart_Time = iTime(_Symbol, HTF_Period, 1);
            chochFired = true;
         }
         
         if(chochFired)
         {
            htfCurrentChochLevel = 0;
            htfLevel2Price = 0;
            htfRetracementStarted = false;
            htfMotherCandleActive = false;
            htfAbcdeActive = false;
            htfAbcdeWave = 0;
            htfAbcdeRetraceRuleCount = 0;
            htfAbcdeA_BodyBroken = false;
            htfPendingChochOrigin = "Normal";
         }
         else
         {
            // Stuck recovery: If the price has moved 500+ points away from ChoCh level
            // and it hasn't fired after 50 bars, force clear
            double distance = MathAbs(currentClose - htfCurrentChochLevel);
            int barsSinceBos = iBarShift(_Symbol, HTF_Period, htfLastSwitchTime);
            if(distance > 500 * _Point && barsSinceBos > 50)
            {
               Print("⚠️ HTF ChoCh stuck (>50 bars, price 500+ pts away). Force clearing.");
               htfCurrentChochLevel = 0;
               htfLevel2Price = 0;
            }
         }
      }
   }
   
   // ==========================================================
   // 4. DEBUG LOG
   // ==========================================================
   Print("🔍 HTF_ABCDE DEBUG | Wave=", htfAbcdeWave, 
         " | Active=", htfAbcdeActive, 
         " | RetStarted=", htfRetracementStarted,
         " | RefHigh=", htfReferenceHighForInvalidation,
         " | RefLow=", htfReferenceLowForInvalidation,
         " | ChoCh=", htfCurrentChochLevel,
         " | 0=", htfAbcde0, " @ ", TimeToString(htfAbcde0_Time),
         " | A=", htfAbcdeA, " @ ", TimeToString(htfAbcdeA_Time),
         " | A_BodyBroken=", htfAbcdeA_BodyBroken,
         " | TrendDir=", htfTrendDirection);
   
   // ==========================================================
   // 5. FINAL DRAWS
   // ==========================================================
   if((ENUM_TIMEFRAMES)Period() == HTF_Period)
   {
      if(ShowHTFTrendLabel) DrawHTFTrendLabel();
      if(htfAbcdeWave >= 1) HTF_DrawABCDEVisuals();
   }
   
   UpdateDashboard();
}

#endif // HTF_TREND_MQH
//+------------------------------------------------------------------+