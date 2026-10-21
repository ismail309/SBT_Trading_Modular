//+------------------------------------------------------------------+
//|                                               SBT_Position.mqh   |
//|                                    Copyright 2026, sbt_trading   |
//|  Position management: partial profit at Level 3 + breakeven.     |
//+------------------------------------------------------------------+
#ifndef SBT_POSITION_MQH
#define SBT_POSITION_MQH

#include "SBT_Entry_Models.mqh"

//+------------------------------------------------------------------+
//| Check Partial Profit                                             |
//+------------------------------------------------------------------+
void CheckPartialProfit()
{
   if(!positionOpen) return;
   if(!UseBreakeven) return;
   if(partialProfitTaken) return;
   if(currentLevel3Price <= 0) return;
   if(mainPositionTicket == 0) return;
   if(!PositionSelectByTicket(mainPositionTicket)) return;
   if(PositionGetString(POSITION_SYMBOL) != _Symbol) return;
   if(PositionGetInteger(POSITION_MAGIC) != ea_magic) return;

   long posType = PositionGetInteger(POSITION_TYPE);
   double currentPrice = SymbolInfoDouble(_Symbol, posType == POSITION_TYPE_BUY ? SYMBOL_BID : SYMBOL_ASK);
   double entryPrice = PositionGetDouble(POSITION_PRICE_OPEN);
   double currentVolume = PositionGetDouble(POSITION_VOLUME);
   double currentTP = PositionGetDouble(POSITION_TP);

   bool level3Reached = false;
   if(posType == POSITION_TYPE_BUY)
      level3Reached = (currentPrice >= currentLevel3Price);
   else if(posType == POSITION_TYPE_SELL)
      level3Reached = (currentPrice <= currentLevel3Price);

   if(!level3Reached) return;

   double partialLot = currentVolume * (PartialProfitPercent / 100.0);
   double step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   if(step <= 0) step = 0.01;
   partialLot = MathFloor(partialLot / step) * step;
   double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   if(partialLot < minLot) partialLot = minLot;

   if(partialLot >= minLot && partialLot < currentVolume)
   {
      if(trade.PositionClosePartial(mainPositionTicket, partialLot))
      {
         partialProfitTaken = true;
         double remainingLot = currentVolume - partialLot;
         if(remainingLot > 0)
         {
            if(PositionSelectByTicket(mainPositionTicket))
            {
               MqlTradeRequest modifyRequest = {};
               MqlTradeResult modifyResult = {};

               modifyRequest.action = TRADE_ACTION_SLTP;
               modifyRequest.position = mainPositionTicket;
               modifyRequest.symbol = _Symbol;
               modifyRequest.sl = entryPrice;
               modifyRequest.tp = currentTP;
               modifyRequest.magic = ea_magic;

               OrderSend(modifyRequest, modifyResult);
            }
         }
      }
   }
   else
   {
      if(trade.PositionClose(mainPositionTicket))
      {
         partialProfitTaken = true;
         positionOpen = false;
      }
   }
}

//+------------------------------------------------------------------+
//| Update Position Management (Breakeven)                           |
//+------------------------------------------------------------------+
void UpdatePositionManagement()
{
   if(!positionOpen) return;
   if(!UseBreakeven) return;
   if(partialProfitTaken) return;
   if(currentLevel3Price <= 0) return;
   if(mainPositionTicket == 0) return;
   if(!PositionSelectByTicket(mainPositionTicket)) return;
   if(PositionGetString(POSITION_SYMBOL) != _Symbol) return;
   if(PositionGetInteger(POSITION_MAGIC) != ea_magic) return;

   long posType = PositionGetInteger(POSITION_TYPE);
   double currentPrice = SymbolInfoDouble(_Symbol, posType == POSITION_TYPE_BUY ? SYMBOL_BID : SYMBOL_ASK);
   double currentSL = PositionGetDouble(POSITION_SL);
   double entryPrice = PositionGetDouble(POSITION_PRICE_OPEN);
   double currentTP = PositionGetDouble(POSITION_TP);

   bool level3Reached = false;
   if(posType == POSITION_TYPE_BUY)
      level3Reached = (currentPrice >= currentLevel3Price);
   else if(posType == POSITION_TYPE_SELL)
      level3Reached = (currentPrice <= currentLevel3Price);

   if(level3Reached && currentSL != entryPrice)
   {
      MqlTradeRequest request = {};
      MqlTradeResult result = {};

      request.action = TRADE_ACTION_SLTP;
      request.position = mainPositionTicket;
      request.symbol = _Symbol;
      request.sl = entryPrice;
      request.tp = currentTP;
      request.magic = ea_magic;

      OrderSend(request, result);
   }
}

#endif // SBT_POSITION_MQH
//+------------------------------------------------------------------+