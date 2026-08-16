//+------------------------------------------------------------------+
//| AiSignalClient.mqh                                                |
//| Calls the local kv_ai_service over WebRequest() and validates the |
//| response per docs/KV_AI_MT5_EA_SPEC_v1.1.md ss4.3/4.4. On ANY     |
//| failure (network, non-200, malformed/expired JSON) this returns   |
//| false and callers MUST treat the signal as unavailable (fall back |
//| to HOLD) - never guess BUY/SELL from partial data.                |
//|                                                                    |
//| KNOWN RISK / not yet compile-verified (blocked on CI, see         |
//| docs/BUG_LOG.md BUG-002): the uchar[]/char[] array types used with|
//| StringToCharArray()/WebRequest() and the ISO-8601 string handling |
//| are the most likely source of first-compile errors in this file.  |
//|                                                                    |
//| KNOWN LIMITATION: staleness/expiry checks compare against          |
//| TimeGMT() (this PC's UTC clock) to match the AI service's UTC     |
//| timestamps, while OHLC bar timestamps sent in the request remain  |
//| broker/server time (informational only, not used for freshness    |
//| checks). Verify TimeGMT() behaves as expected on the actual       |
//| broker/VPS during forward-test (spec ss12.4).                     |
//+------------------------------------------------------------------+
#ifndef KV_AI_AI_SIGNAL_CLIENT_MQH
#define KV_AI_AI_SIGNAL_CLIENT_MQH

#include "JsonLite.mqh"

#define KV_AI_SCHEMA_VERSION "1.0"

struct SAiSignal
  {
   bool     valid;
   string   signal;
   double   confidence;
   double   stop_loss_pips;
   double   take_profit_pips;
   string   reasoning;
   datetime generated_at;
   datetime expiry_ts;
  };

string TimeToIso8601(const datetime t)
  {
   string s = TimeToString(t, TIME_DATE | TIME_SECONDS);
   StringReplace(s, ".", "-");
   StringReplace(s, " ", "T");
   return(s + "Z");
  }

datetime Iso8601ToTime(const string iso)
  {
   string s = iso;
   int dot = StringFind(s, ".");
   if(dot >= 0)
      s = StringSubstr(s, 0, dot);
   StringReplace(s, "T", " ");
   StringReplace(s, "Z", "");
   StringReplace(s, "-", ".");
   return(StringToTime(s));
  }

//+------------------------------------------------------------------+
//| Fetches and validates an AI signal for 'symbol'. Returns false    |
//| (out.valid=false) on any network/validation failure.              |
//+------------------------------------------------------------------+
bool RequestAiSignal(const string baseUrl,
                      const string symbol,
                      const string timeframeLabel,
                      const int barsCount,
                      const int timeoutMs,
                      const int maxSignalAgeSec,
                      const string openPositionSide,
                      const double openPositionVolume,
                      const double openPositionEntryPrice,
                      SAiSignal &out)
  {
   ZeroMemory(out);
   out.valid = false;

   string requestId = StringFormat("%d-%d", (int)TimeGMT(), MathRand());
   datetime asOfGmt = TimeGMT();

   int available = Bars(symbol, PERIOD_CURRENT);
   int n = (barsCount < available) ? barsCount : available;

   string bars = "";
   for(int i = n - 1; i >= 0; i--)
     {
      if(StringLen(bars) > 0)
         bars += ",";
      bars += StringFormat(
         "{\"t\":\"%s\",\"o\":%.5f,\"h\":%.5f,\"l\":%.5f,\"c\":%.5f,\"v\":%.2f}",
         TimeToIso8601(iTime(symbol, PERIOD_CURRENT, i)),
         iOpen(symbol, PERIOD_CURRENT, i),
         iHigh(symbol, PERIOD_CURRENT, i),
         iLow(symbol, PERIOD_CURRENT, i),
         iClose(symbol, PERIOD_CURRENT, i),
         (double)iVolume(symbol, PERIOD_CURRENT, i));
     }

   string body = StringFormat(
      "{\"schema_version\":\"%s\",\"request_id\":\"%s\",\"symbol\":\"%s\",\"timeframe\":\"%s\"," +
      "\"as_of\":\"%s\",\"ohlc_window\":[%s],\"open_position\":{\"side\":\"%s\",\"volume\":%.2f,\"entry_price\":%.5f}}",
      KV_AI_SCHEMA_VERSION,
      requestId,
      JsonEscape(symbol),
      JsonEscape(timeframeLabel),
      TimeToIso8601(asOfGmt),
      bars,
      openPositionSide,
      openPositionVolume,
      openPositionEntryPrice);

   uchar postData[];
   int rawLen = StringToCharArray(body, postData, 0, StringLen(body), CP_UTF8);
   ArrayResize(postData, rawLen - 1); // drop the trailing zero terminator

   string headers = "Content-Type: application/json\r\n";
   uchar resultData[];
   string resultHeaders;

   ResetLastError();
   int status = WebRequest("POST", baseUrl + "/v1/signal", headers, timeoutMs,
                            postData, resultData, resultHeaders);
   if(status != 200)
     {
      PrintFormat("KV_AI AiSignalClient: WebRequest failed, status=%d, error=%d", status, GetLastError());
      return(false);
     }

   string responseText = CharArrayToString(resultData, 0, -1, CP_UTF8);

   string schemaVersion, signalValue, reasoning, respRequestId;
   double confidence, slPips, tpPips;
   string generatedAtStr, expiryStr;

   if(!JsonExtractString(responseText, "schema_version", schemaVersion) || schemaVersion != KV_AI_SCHEMA_VERSION)
     {
      Print("KV_AI AiSignalClient: schema_version missing or mismatched");
      return(false);
     }
   if(!JsonExtractString(responseText, "request_id", respRequestId) || respRequestId != requestId)
     {
      Print("KV_AI AiSignalClient: request_id missing or mismatched");
      return(false);
     }
   if(!JsonExtractString(responseText, "signal", signalValue) ||
      (signalValue != "BUY" && signalValue != "SELL" && signalValue != "HOLD"))
     {
      Print("KV_AI AiSignalClient: invalid or missing signal value");
      return(false);
     }
   if(!JsonExtractNumber(responseText, "confidence", confidence) || confidence < 0.0 || confidence > 1.0)
     {
      Print("KV_AI AiSignalClient: invalid or missing confidence value");
      return(false);
     }
   if(!JsonExtractNumber(responseText, "stop_loss_pips", slPips) || slPips < 0.0)
     {
      Print("KV_AI AiSignalClient: invalid or missing stop_loss_pips value");
      return(false);
     }
   if(!JsonExtractNumber(responseText, "take_profit_pips", tpPips) || tpPips < 0.0)
     {
      Print("KV_AI AiSignalClient: invalid or missing take_profit_pips value");
      return(false);
     }
   if(!JsonExtractString(responseText, "generated_at", generatedAtStr))
     {
      Print("KV_AI AiSignalClient: missing generated_at");
      return(false);
     }
   if(!JsonExtractString(responseText, "expiry_ts", expiryStr))
     {
      Print("KV_AI AiSignalClient: missing expiry_ts");
      return(false);
     }
   JsonExtractString(responseText, "reasoning", reasoning);

   datetime generatedAt = Iso8601ToTime(generatedAtStr);
   datetime expiryTs = Iso8601ToTime(expiryStr);
   datetime nowGmt = TimeGMT();

   if(expiryTs <= nowGmt)
     {
      Print("KV_AI AiSignalClient: signal already expired (stale)");
      return(false);
     }
   if((nowGmt - generatedAt) > maxSignalAgeSec)
     {
      Print("KV_AI AiSignalClient: signal too old (generated_at stale)");
      return(false);
     }

   out.valid             = true;
   out.signal             = signalValue;
   out.confidence          = confidence;
   out.stop_loss_pips      = slPips;
   out.take_profit_pips    = tpPips;
   out.reasoning           = reasoning;
   out.generated_at        = generatedAt;
   out.expiry_ts           = expiryTs;
   return(true);
  }

#endif // KV_AI_AI_SIGNAL_CLIENT_MQH
