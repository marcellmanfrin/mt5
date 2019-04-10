//+------------------------------------------------------------------+
//|                                                     ATRBands.mq5 |
//|                        Copyright 2019, Marcell Manfrin Barbacena |
//|                                           barbacenaatgmaildotcom |
//+------------------------------------------------------------------+
#property copyright "Copyright 2019, Marcell Manfrin Barbacena"
#property link      "barbacenaatgmaildotcom"
#property version   "1.00"

#property indicator_chart_window
#property indicator_buffers 4
#property indicator_plots   2
#property indicator_type1   DRAW_LINE
#property indicator_color1  LightSeaGreen
#property indicator_type2   DRAW_LINE
#property indicator_color2  LightSeaGreen
#property indicator_width1  1
#property indicator_width2  1
#property indicator_label1  "ATR Upper Band"
#property indicator_label2  "ATR Lower Band"
#property indicator_applied_price PRICE_CLOSE


input double    Factor = 0.8;
input int      ATR = 50;
input int      TEMA = 14;

double                  upperATRBuffer[];
double                  lowerATRBuffer[];

double atrBuffer[];
double temaBuffer[];

int temaf;
int atrf;

int OnInit()
{
   SetIndexBuffer(0,upperATRBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,lowerATRBuffer,INDICATOR_DATA);
   SetIndexBuffer(2,atrBuffer,INDICATOR_DATA);
   SetIndexBuffer(3,temaBuffer,INDICATOR_DATA);
   
   PlotIndexSetString(0,PLOT_LABEL,"ATR Bands Upper");
   PlotIndexSetString(1,PLOT_LABEL,"ATR Bands Lower");

   PlotIndexSetInteger(0, PLOT_SHIFT, 0);
   PlotIndexSetInteger(0, PLOT_DRAW_BEGIN, ATR-1);

   temaf = iTEMA(_Symbol, _Period, TEMA, 0, indicator_applied_price);
   atrf = iATR(_Symbol, _Period, ATR);
     
   return(INIT_SUCCEEDED);
}

int OnCalculate(const int rates_total,
                const int prev_calculated,
                const int begin,
                const double &price[])
{
   if (rates_total < ATR - 1 + begin) {
      return 0;
   }
   CopyBuffer(temaf,0,0,rates_total,temaBuffer);
   CopyBuffer(atrf,0,0,rates_total,atrBuffer);
   
   for (int i = 0; i < rates_total; i++) {
      upperATRBuffer[i] = temaBuffer[i]+atrBuffer[i]*Factor;
      lowerATRBuffer[i] = temaBuffer[i]-atrBuffer[i]*Factor;
   }

   return(rates_total);
}
