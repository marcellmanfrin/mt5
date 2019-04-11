//+------------------------------------------------------------------+
//|                                                   MarcellLib.mqh |
//|                                  Copyright 2019, Marcell Manfrin |
//+------------------------------------------------------------------+
#property copyright "Copyright 2019, Marcell Manfrin"
#property link      ""


#include <Object.mqh>
#include <MQL_Easy\MQL_Easy.mqh>
//+------------------------------------------------------------------+

MqlTick GetTick() {
   MqlTick tick; // Structure to get the latest prices      
   SymbolInfoTick(Symbol(), tick);
   return tick;
}

int _MAGIC = 855500;

class PositionTrade : public CObject {
   private:
      bool open, run, done;
      double openVolume, takeProfit, stopLoss;
      string symbol;
      ENUM_POSITION_TYPE position_type;
      int magicNumber;
      CExecute execute;
      double startPrice;
      long ticket_sl, ticket_tp;
      
   public:
      PositionTrade(string _symbol) {
         open = run = done = false;
         symbol = _symbol;
         magicNumber = _MAGIC++;
         execute.SetSymbol(symbol);
         execute.SetMagicNumber(magicNumber);
         startPrice = 0.0;
      }
      
      void Sell(double volume) {
         openVolume = volume;
         position_type = POSITION_TYPE_SELL;
      }
      
      void Buy(double volume) {
         openVolume = volume;
         position_type = POSITION_TYPE_BUY;
      }
      
      void TakeProfit(double price) {
         takeProfit = price;
      }

      void StopLoss(double price) {
         stopLoss = price;
      }

      void Run() {
         // TODO: send orders
         run = true;
         if (position_type == POSITION_TYPE_BUY) {
            if (startPrice == 0.0) {
               execute.Position(TYPE_POSITION_BUY, openVolume);
            } else {
               // Limit
            }
         }
         else {
            if (startPrice == 0.0) {
               execute.Position(TYPE_POSITION_SELL, openVolume);
            } else {
               // Limit
            }
         }
      }
      
      bool Running() {
         return run;
      }
      
      void Update() {
         if (done) {
            // Encerrado
         } else {
            if (open) {
               // Abriu posicao! Acompanhar ordens
               COrder orders(symbol,magicNumber);
               int count = orders.GroupTotal();
               long tck = orders.SelectByTicket(ticket_sl);
               if (!tck) {
                  orders[ticket_tp].Close();
                  done = true;
                  open = run = false;
               }
               tck = orders.SelectByTicket(ticket_tp);
               if (!tck) {
                  orders[ticket_sl].Close();
                  done = true;
                  open = run = false;
               }
            } else if (run) {
               // Iniciou, capturando posicao
               CPosition position(symbol,magicNumber);
               int total = position.GroupTotal();
               long tck = position.SelectByIndex(0);
               if (total > 0 && tck) {
                  open = true;
                  startPrice = position.GetPriceOpen();
                  if (position_type == POSITION_TYPE_BUY) {
                     ticket_sl = execute.Order(TYPE_ORDER_SELLLIMIT, openVolume, stopLoss);
                     ticket_tp = execute.Order(TYPE_ORDER_SELLLIMIT, openVolume, takeProfit);
                  } else {
                     ticket_sl = execute.Order(TYPE_ORDER_BUYLIMIT, openVolume, stopLoss);
                     ticket_tp = execute.Order(TYPE_ORDER_BUYLIMIT, openVolume, takeProfit);
                  }
               }
            }
         }
      }
};
