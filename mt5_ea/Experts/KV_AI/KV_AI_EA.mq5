//+------------------------------------------------------------------+
//| KV_AI_EA.mq5                                                     |
//| Spec: docs/KV_AI_MT5_EA_SPEC_v1.1.md                              |
//+------------------------------------------------------------------+
#property copyright "KV_AI"
#property version   "0.1"
#property strict

enum ENUM_SIGNAL_MODE
  {
   SIGNAL_MODE_DAVIT_ONLY = 0,
   SIGNAL_MODE_AI_ONLY    = 1,
   SIGNAL_MODE_COMBINED   = 2
  };

enum ENUM_VOLUME_MODE
  {
   VOLUME_MODE_FIXED_LOT               = 0,
   VOLUME_MODE_RISK_PERCENT            = 1,
   VOLUME_MODE_RISK_PERCENT_CAPPED_KELLY = 2
  };

#include "../../Include/KV_AI/SignalRouter.mqh"

input string            InpSymbol               = "XAUUSD";
input ENUM_SIGNAL_MODE  InpSignalMode           = SIGNAL_MODE_COMBINED;
input ENUM_VOLUME_MODE  InpVolumeMode           = VOLUME_MODE_RISK_PERCENT;
input double            InpFixedLot             = 0.01;
input double            InpMaxRiskPerTradePct   = 1.0;
input double            InpMaxTotalRiskPct      = 5.0;
input double            InpMaxMarginUsagePct    = 50.0;
input double            InpKellyFraction        = 0.5;
input string            InpAiServiceUrl         = "http://127.0.0.1:8765";
input int               InpAiTimeoutMs          = 3000;
input int               InpMaxSignalAgeSec      = 120;
input int               InpMaxRetry             = 3;
input long              InpMagicNumber          = 20260816;

datetime g_lastHeartbeat = 0;

//+------------------------------------------------------------------+
int OnInit()
  {
   if(InpMaxRiskPerTradePct <= 0.0 || InpMaxRiskPerTradePct > InpMaxTotalRiskPct)
     {
      Print("KV_AI_EA: invalid risk configuration, InpMaxRiskPerTradePct must be > 0 and <= InpMaxTotalRiskPct");
      return(INIT_PARAMETERS_INCORRECT);
     }
   if(InpMaxMarginUsagePct <= 0.0 || InpMaxMarginUsagePct > 100.0)
     {
      Print("KV_AI_EA: invalid InpMaxMarginUsagePct, must be in (0, 100]");
      return(INIT_PARAMETERS_INCORRECT);
     }

   Print("KV_AI_EA: initialized symbol=", InpSymbol,
         " mode=", EnumToString(InpSignalMode),
         " volumeMode=", EnumToString(InpVolumeMode));
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   Print("KV_AI_EA: deinit, reason=", reason);
  }

//+------------------------------------------------------------------+
//| M3: computes and logs the routed signal every tick. No order      |
//| execution yet - RiskManager/RolloverGuard/OrderGuard land in      |
//| M4-M6 per docs/KV_AI_MT5_EA_SPEC_v1.1.md before any OrderSend().  |
//+------------------------------------------------------------------+
void OnTick()
  {
   if(TimeCurrent() - g_lastHeartbeat < 60)
      return;
   g_lastHeartbeat = TimeCurrent();

   double bid = SymbolInfoDouble(InpSymbol, SYMBOL_BID);

   SPivotLevels levels;
   bool havePivot = CalcPivot(InpSymbol, TimeCurrent(), levels);
   ENUM_TRADE_SIGNAL davitSignal = havePivot ? DavitSignalFromPivot(bid, levels) : TRADE_SIGNAL_HOLD;

   SAiSignal aiSignal;
   bool haveAi = false;
   if(InpSignalMode == SIGNAL_MODE_AI_ONLY || InpSignalMode == SIGNAL_MODE_COMBINED)
      haveAi = RequestAiSignal(InpAiServiceUrl, InpSymbol, "H1", 50, InpAiTimeoutMs, InpMaxSignalAgeSec,
                                "NONE", 0.0, 0.0, aiSignal);

   ENUM_TRADE_SIGNAL routed = RouteSignal(InpSignalMode, davitSignal, haveAi,
                                           haveAi ? AiSignalToTradeSignal(aiSignal.signal) : TRADE_SIGNAL_HOLD);

   PrintFormat("KV_AI_EA: heartbeat symbol=%s bid=%.5f davit=%d aiValid=%s routed=%d",
               InpSymbol, bid, (int)davitSignal, haveAi ? "true" : "false", (int)routed);
  }
//+------------------------------------------------------------------+
