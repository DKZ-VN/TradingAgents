//+------------------------------------------------------------------+
//| PivotDavit.mqh                                                    |
//| PLACEHOLDER pivot source - NOT the real "Davit Pivot" (ForexFactory|
//| thread) formula yet. See docs/KV_AI_MT5_EA_SPEC_v1.1.md ss 12.1.  |
//| Callers depend only on SPivotLevels + CalcPivot() below, so the   |
//| real formula can replace this file's body without touching the EA.|
//+------------------------------------------------------------------+
#ifndef KV_AI_PIVOT_DAVIT_MQH
#define KV_AI_PIVOT_DAVIT_MQH

struct SPivotLevels
  {
   double   pp;
   double   r1, r2, r3;
   double   s1, s2, s3;
   double   fib_r1, fib_r2, fib_r3;
   double   fib_s1, fib_s2, fib_s3;
   datetime week_start;
   bool     valid;
  };

//+------------------------------------------------------------------+
//| Computes classic + Fibonacci pivot levels from the last fully     |
//| closed weekly bar as of 'asOf'. Returns false if weekly history   |
//| is unavailable (e.g. not enough bars loaded yet).                 |
//+------------------------------------------------------------------+
bool CalcPivot(const string symbol, const datetime asOf, SPivotLevels &out)
  {
   ZeroMemory(out);
   out.valid = false;

   int shift = iBarShift(symbol, PERIOD_W1, asOf, false);
   if(shift < 0)
      return(false);
   int prevWeekShift = shift + 1;

   double high  = iHigh(symbol, PERIOD_W1, prevWeekShift);
   double low   = iLow(symbol, PERIOD_W1, prevWeekShift);
   double close = iClose(symbol, PERIOD_W1, prevWeekShift);
   datetime weekStart = iTime(symbol, PERIOD_W1, prevWeekShift);

   if(high <= 0.0 || low <= 0.0 || high < low)
      return(false);

   double range = high - low;
   out.pp = (high + low + close) / 3.0;

   out.r1 = 2.0 * out.pp - low;
   out.s1 = 2.0 * out.pp - high;
   out.r2 = out.pp + range;
   out.s2 = out.pp - range;
   out.r3 = high + 2.0 * (out.pp - low);
   out.s3 = low - 2.0 * (high - out.pp);

   out.fib_r1 = out.pp + 0.382 * range;
   out.fib_r2 = out.pp + 0.618 * range;
   out.fib_r3 = out.pp + 1.000 * range;
   out.fib_s1 = out.pp - 0.382 * range;
   out.fib_s2 = out.pp - 0.618 * range;
   out.fib_s3 = out.pp - 1.000 * range;

   out.week_start = weekStart;
   out.valid = true;
   return(true);
  }

#endif // KV_AI_PIVOT_DAVIT_MQH
