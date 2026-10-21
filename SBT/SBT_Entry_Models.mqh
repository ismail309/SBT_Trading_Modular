//+------------------------------------------------------------------+
//|                                           SBT_Entry_Models.mqh   |
//|                                    Copyright 2026, sbt_trading   |
//|  Entry execution + SBT-1 entry model.                            |
//+------------------------------------------------------------------+
#ifndef SBT_ENTRY_MODELS_MQH
#define SBT_ENTRY_MODELS_MQH

#include "SBT_Zones.mqh"

//+------------------------------------------------------------------+
//| Order execution                                                  |
//+------------------------------------------------------------------+
void OpenBuyOrder(double price, double sl, double tp, double lotSize)
{
   MqlTradeRequest request = {};
   MqlTradeResult result = {};

   request.action = TRADE_ACTION_DEAL;
   request.symbol = _Symbol;
   request.volume = lotSize;
   request.type = ORDER_TYPE_BUY;
   request.price = price;
   request.sl = sl;
   request.tp = tp;
   request.deviation = 10;
   request.type_filling = ORDER_FILLING_FOK;
   request.magic = ea_magic;

   if(!OrderSend(request, result))
   {
      Print("❌ BUY ORDER FAILED: ", result.retcode);
      return;
   }

   positionOpen = true;
   mainPositionTicket = result.order;
   mainPositionEntry = price;
   mainPositionSL = sl;
   mainPositionTP = tp;
   mainPositionLot = lotSize;
   partialProfitTaken = false;
   currentPositionCount = GetCurrentPositionCount();
}

void OpenSellOrder(double price, double sl, double tp, double lotSize)
{
   MqlTradeRequest request = {};
   MqlTradeResult result = {};

   request.action = TRADE_ACTION_DEAL;
   request.symbol = _Symbol;
   request.volume = lotSize;
   request.type = ORDER_TYPE_SELL;
   request.price = price;
   request.sl = sl;
   request.tp = tp;
   request.deviation = 10;
   request.type_filling = ORDER_FILLING_FOK;
   request.magic = ea_magic;

   if(!OrderSend(request, result))
   {
      Print("❌ SELL ORDER FAILED: ", result.retcode);
      return;
   }

   positionOpen = true;
   mainPositionTicket = result.order;
   mainPositionEntry = price;
   mainPositionSL = sl;
   mainPositionTP = tp;
   mainPositionLot = lotSize;
   partialProfitTaken = false;
   currentPositionCount = GetCurrentPositionCount();
}

//+------------------------------------------------------------------+
//| Check SBT-1 Entry                                                |
//+------------------------------------------------------------------+
void CheckSBT1Entry()
{
   EnsureSLPriceIsSet();

   if(currentSLPrice <= 0) return;
   if(!CanOpenNewPosition()) return;

   if(trendDirection == 1)  // BULLISH
   {
      if(!dzConfirmed) return;
      if(dzMitigated) return;

      double currentClose = iClose(_Symbol, PERIOD_CURRENT, 1);
      double currentHigh = iHigh(_Symbol, PERIOD_CURRENT, 1);
      double currentLow = iLow(_Symbol, PERIOD_CURRENT, 1);

      bool priceTouchedDZ = (currentHigh >= dzBottomPrice && currentLow <= dzTopPrice);
      bool bodyClosedAboveLevel2 = (currentClose > dzBottomPrice);

      if(!priceTouchedDZ) return;
      if(!bodyClosedAboveLevel2) return;

      double entryPrice = iOpen(_Symbol, PERIOD_CURRENT, 0);
      double slPrice = currentSLPrice;

      if(slPrice >= entryPrice) return;

      double risk = entryPrice - slPrice;
      double tpPrice = entryPrice + (risk * RiskRewardRatio);
      double lotSize = CalculateLotSize(slPrice, entryPrice);

      Print("✅ SBT-1 BULLISH ENTRY! Entry=", entryPrice, " SL=", slPrice, " TP=", tpPrice, " Lots=", lotSize);
      OpenBuyOrder(entryPrice, slPrice, tpPrice, lotSize);

      dzMitigated = true;
      if(ObjectFind(0, "DemandZone_Label") >= 0)
         ObjectSetString(0, "DemandZone_Label", OBJPROP_TEXT, "DZ (mitigated)");
   }
   else  // BEARISH
   {
      if(!szConfirmed) return;
      if(szMitigated) return;

      double currentClose = iClose(_Symbol, PERIOD_CURRENT, 1);
      double currentHigh = iHigh(_Symbol, PERIOD_CURRENT, 1);
      double currentLow = iLow(_Symbol, PERIOD_CURRENT, 1);

      double szTop = szTopPrice;
      double szBottom = szBottomPrice;

      bool priceTouchedSZ = (currentHigh >= szBottom && currentLow <= szTop);
      bool bodyNotAboveSZTop = (currentClose <= szTop);

      if(!priceTouchedSZ) return;
      if(!bodyNotAboveSZTop) return;

      double entryPrice = iOpen(_Symbol, PERIOD_CURRENT, 0);
      double slPrice = currentSLPrice;

      if(slPrice <= entryPrice) return;

      double risk = slPrice - entryPrice;
      if(risk <= 0) return;

      double tpPrice = entryPrice - (risk * RiskRewardRatio);
      double lotSize = CalculateLotSize(slPrice, entryPrice);
      if(lotSize <= 0) return;

      Print("✅ SBT-1 BEARISH ENTRY! Entry=", entryPrice, " SL=", slPrice, " TP=", tpPrice, " Lots=", lotSize);
      OpenSellOrder(entryPrice, slPrice, tpPrice, lotSize);

      szMitigated = true;
      if(ObjectFind(0, "SupplyZone_Label") >= 0)
         ObjectSetString(0, "SupplyZone_Label", OBJPROP_TEXT, "SZ (mitigated)");
   }
}

#endif // SBT_ENTRY_MODELS_MQH
//+------------------------------------------------------------------+