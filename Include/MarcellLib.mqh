//+------------------------------------------------------------------+
//|                                                   MarcellLib.mqh |
//|                                  Copyright 2019, Marcell Manfrin |
//+------------------------------------------------------------------+
#property copyright "Copyright 2019, Marcell Manfrin"
#property link      ""


#include <Object.mqh>
#include <MQL_Easy\MQL_Easy.mqh>
#include <Trade\Trade.mqh>
//+------------------------------------------------------------------+

MqlTick GetTick() {
   MqlTick tick; // Structure to get the latest prices      
   SymbolInfoTick(Symbol(), tick);
   return tick;
}

MqlRates GetCurrentRate() {
   MqlRates rates[];
   CopyRates(Symbol(),0,0,1,rates);
   return rates[0];
}

int _MAGIC = 855000;

class PositionTrade : public CObject {
   private:
      bool open, run, done, loss;
      double openVolume, takeProfit, stopLoss;
      string symbol;
      ENUM_POSITION_TYPE position_type;
      int magicNumber;
      CExecute execute;
      double startPrice;
      long ticket_sl, ticket_tp;
      CTrade _trade;
      
   public:
      PositionTrade(string _symbol) {
         open = run = done = loss = false;
         symbol = _symbol;
         magicNumber = _MAGIC++;
         execute.SetSymbol(symbol);
         execute.SetMagicNumber(magicNumber);
         startPrice = 0.0;
         _trade.SetExpertMagicNumber(magicNumber);
      }
      
      void Sell(double volume) {
         openVolume = volume;
         position_type = POSITION_TYPE_SELL;
      }
      
      void Buy(double volume) {
         openVolume = volume;
         position_type = POSITION_TYPE_BUY;
      }
      
      void Sell(double volume, double price) {
         openVolume = volume;
         startPrice = price;
         position_type = POSITION_TYPE_SELL;
      }
      
      void Buy(double volume, double price) {
         openVolume = volume;
         startPrice = price;
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
               _trade.BuyLimit(openVolume,startPrice,symbol,0,0,ORDER_TIME_DAY,0);
               if (_trade.ResultOrder() <= 0) {
                  _trade.BuyStop(openVolume,startPrice,symbol,0,0,ORDER_TIME_DAY,0);
               }
            }
         }
         else {
            if (startPrice == 0.0) {
               execute.Position(TYPE_POSITION_SELL, openVolume);
            } else {
               // Limit
               // Limit
               _trade.SellLimit(openVolume,startPrice,symbol,0,0,ORDER_TIME_DAY,0);
               if (_trade.ResultOrder() <= 0) {
                  _trade.SellStop(openVolume,startPrice,symbol,0,0,ORDER_TIME_DAY,0);
               }
            }
         }
      }
      
      bool Running() {
         return run;
      }
      
      bool Loss() {
         return loss;
      }
      
      void Update() {
         if (done) {
            // Encerrado
         } else {
            if (open) {
               // Abriu posicao! Acompanhar ordens
               
               //COrder orders(symbol,magicNumber);
               //int count = orders.GroupTotal();
               if (!OrderSelect(ticket_sl)) {
                  if (OrderSelect(ticket_tp)) {
                     _trade.OrderDelete(ticket_tp);
                  }
                  done = loss = true;
                  open = run = false;
               }
               if (!OrderSelect(ticket_tp)) {
                  if (OrderSelect(ticket_sl)) {
                     _trade.OrderDelete(ticket_sl);
                  }
                  done = true;
                  open = run = false;
               }
            } else if (run) {
               // Iniciou, capturando posicao
               
               CPosition position(symbol,magicNumber);
               int total = position.GroupTotal();
               if (total > 0) {
                  long tck = position.SelectByIndex(0);
                  open = true;
                  startPrice = position.GetPriceOpen();
                  if (position_type == POSITION_TYPE_BUY) {
                     _trade.SellStop(openVolume,startPrice-stopLoss,symbol,0,0,ORDER_TIME_DAY,0);
                     ticket_sl = (long) _trade.ResultOrder();
                     _trade.SellLimit(openVolume,startPrice+takeProfit,symbol,0,0,ORDER_TIME_DAY,0);
                     ticket_tp = (long) _trade.ResultOrder();
                  } else {
                     _trade.BuyStop(openVolume,startPrice+stopLoss,symbol,0,0,ORDER_TIME_DAY,0);
                     ticket_sl = (long) _trade.ResultOrder();
                     _trade.BuyLimit(openVolume,startPrice-takeProfit,symbol,0,0,ORDER_TIME_DAY,0);
                     ticket_tp = (long) _trade.ResultOrder();
                  }
               }
            }
         }
      }
};
