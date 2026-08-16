//+------------------------------------------------------------------+
//| SignalRouter.mqh                                                  |
//| Combines the Davit-pivot-derived signal and the AI signal per the |
//| EA's ENUM_SIGNAL_MODE (docs/KV_AI_MT5_EA_SPEC_v1.1.md ss1/4.4).   |
//+------------------------------------------------------------------+
#ifndef KV_AI_SIGNAL_ROUTER_MQH
#define KV_AI_SIGNAL_ROUTER_MQH

#include "PivotDavit.mqh"
#include "AiSignalClient.mqh"

enum ENUM_TRADE_SIGNAL
  {
   TRADE_SIGNAL_HOLD = 0,
   TRADE_SIGNAL_BUY  = 1,
   TRADE_SIGNAL_SELL = 2
  };

//+------------------------------------------------------------------+
//| PLACEHOLDER Davit-side entry rule: derives BUY/SELL/HOLD from the |
//| placeholder pivot levels (docs spec ss12.1). This is NOT the real |
//| "Davit Pivot" trading rule - just enough structure to exercise    |
//| SignalRouter/COMBINED mode end-to-end until the real rule is      |
//| supplied. Replace the body once available; keep the signature.   |
//+------------------------------------------------------------------+
ENUM_TRADE_SIGNAL DavitSignalFromPivot(const double currentPrice, const SPivotLevels &levels)
  {
   if(!levels.valid)
      return(TRADE_SIGNAL_HOLD);

   if(currentPrice > levels.pp && currentPrice < levels.r1)
      return(TRADE_SIGNAL_BUY);
   if(currentPrice < levels.pp && currentPrice > levels.s1)
      return(TRADE_SIGNAL_SELL);

   return(TRADE_SIGNAL_HOLD);
  }

ENUM_TRADE_SIGNAL AiSignalToTradeSignal(const string aiSignal)
  {
   if(aiSignal == "BUY")
      return(TRADE_SIGNAL_BUY);
   if(aiSignal == "SELL")
      return(TRADE_SIGNAL_SELL);
   return(TRADE_SIGNAL_HOLD);
  }

//+------------------------------------------------------------------+
//| Combines the two signal sources per mode. In COMBINED mode, a     |
//| failed/unavailable AI signal forces HOLD outright (spec ss4.4) -  |
//| it never silently falls back to DAVIT_ONLY behaviour.             |
//+------------------------------------------------------------------+
ENUM_TRADE_SIGNAL RouteSignal(const ENUM_SIGNAL_MODE mode,
                               const ENUM_TRADE_SIGNAL davitSignal,
                               const bool aiValid,
                               const ENUM_TRADE_SIGNAL aiSignal)
  {
   switch(mode)
     {
      case SIGNAL_MODE_DAVIT_ONLY:
         return(davitSignal);

      case SIGNAL_MODE_AI_ONLY:
         return(aiValid ? aiSignal : TRADE_SIGNAL_HOLD);

      case SIGNAL_MODE_COMBINED:
         if(!aiValid)
            return(TRADE_SIGNAL_HOLD);
         if(davitSignal == aiSignal && davitSignal != TRADE_SIGNAL_HOLD)
            return(davitSignal);
         return(TRADE_SIGNAL_HOLD);
     }
   return(TRADE_SIGNAL_HOLD);
  }

#endif // KV_AI_SIGNAL_ROUTER_MQH
