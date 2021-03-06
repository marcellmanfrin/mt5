//+------------------------------------------------------------------+
//|                                                    TemaAtrEA.mq5 |
//|                        Copyright 2019, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2019, Marcell Manfrin Barbacena"
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <MarcellLib.mqh>
#include <MQL_Easy\MQL_Easy.mqh>
#include <Generic\ArrayList.mqh>

#property indicator_applied_price PRICE_CLOSE

input int TEMA_Period = 14;
input int ATR_Period = 14;
input double BandFactor = 1.1;

input double Volume = 1;
input double TakeProfit = 100.0;
input double StopLoss = 150.0;

MqlTick currentTick;
double atrBuffer[];
double temaBuffer[];
int temaf;
int atrf;

CUtilities utils(_Symbol);

CArrayList<PositionTrade*> trades = new CArrayList<PositionTrade*>();

int start()
{
  Comment("Copyright © 2019, Marcell Manfrin");
  return(0);
}

int OnInit() {
   temaf = iTEMA(_Symbol, _Period, TEMA_Period, 0, indicator_applied_price);
   atrf = iATR(_Symbol, _Period, ATR_Period);
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason) {
}

void OnTick() {
   if (ShouldRun()) {
      double up = utils.NormalizePrice(temaBuffer[0] + atrBuffer[0] * BandFactor);
      double down = utils.NormalizePrice(temaBuffer[0] - atrBuffer[0] * BandFactor);
      
      if (trades.Count() > 0 && GetLastTrade().Running()) {
         Comment("Trade aberto");
      } else if (currentTick.last >= up) {
         PositionTrade* trade = new PositionTrade(_Symbol);
         trade.Sell(Volume, currentTick.last);
         trade.TakeProfit(TakeProfit);
         trade.StopLoss(StopLoss);
         trade.Run();
         addTrade(trade);
      } else if (currentTick.last <= down) {
         PositionTrade* trade = new PositionTrade(_Symbol);
         trade.Buy(Volume, currentTick.last);
         trade.TakeProfit(TakeProfit);
         trade.StopLoss(StopLoss);
         trade.Run();
         addTrade(trade);
      } else {
         Comment("Nenhum trade");
      }
   }
}

PositionTrade* GetLastTrade() {
   PositionTrade *trade;
   trades.TryGetValue(trades.Count()-1, trade);
   return trade;
}

void addTrade(PositionTrade &trade) {
   trades.Add(&trade);
}

void OnTrade() {
   GetLastTrade().Update();
}

bool _done = false;

void Stop() {
   _done = true;
}

bool ShouldRun() {
   Process();
   return !_done;
}

void Process() {
   ProcessIndicators();
   currentTick = GetTick();
}

void ProcessIndicators() {
   CopyBuffer(temaf,0,0,1,temaBuffer);
   CopyBuffer(atrf,0,0,1,atrBuffer);
}

