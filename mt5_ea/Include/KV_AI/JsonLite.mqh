//+------------------------------------------------------------------+
//| JsonLite.mqh                                                      |
//| Minimal, dependency-free JSON helpers scoped to the flat EA<->AI  |
//| service contract (docs/KV_AI_MT5_EA_SPEC_v1.1.md ss4). Not a      |
//| general-purpose JSON parser: response payloads have no nested     |
//| arrays/objects, so string/number field extraction is sufficient.  |
//+------------------------------------------------------------------+
#ifndef KV_AI_JSON_LITE_MQH
#define KV_AI_JSON_LITE_MQH

string JsonEscape(const string text)
  {
   string result = text;
   StringReplace(result, "\\", "\\\\");
   StringReplace(result, "\"", "\\\"");
   return(result);
  }

//+------------------------------------------------------------------+
//| Extracts the string value of "key":"value" from a flat JSON      |
//| object. Returns false if the key is missing or the value is not  |
//| a JSON string.                                                    |
//+------------------------------------------------------------------+
bool JsonExtractString(const string json, const string key, string &out)
  {
   string needle = "\"" + key + "\"";
   int keyPos = StringFind(json, needle);
   if(keyPos < 0)
      return(false);

   int colonPos = StringFind(json, ":", keyPos + StringLen(needle));
   if(colonPos < 0)
      return(false);

   int len = StringLen(json);
   int i = colonPos + 1;
   while(i < len && StringGetCharacter(json, i) == ' ')
      i++;
   if(i >= len || StringGetCharacter(json, i) != '"')
      return(false);
   i++;
   int start = i;

   while(i < len)
     {
      ushort ch = StringGetCharacter(json, i);
      if(ch == '\\')
        {
         i += 2;
         continue;
        }
      if(ch == '"')
         break;
      i++;
     }
   if(i >= len)
      return(false);

   out = StringSubstr(json, start, i - start);
   StringReplace(out, "\\\"", "\"");
   StringReplace(out, "\\\\", "\\");
   return(true);
  }

//+------------------------------------------------------------------+
//| Extracts the numeric value of "key": 123.45 (integers, decimals   |
//| and negatives) from a flat JSON object.                           |
//+------------------------------------------------------------------+
bool JsonExtractNumber(const string json, const string key, double &out)
  {
   string needle = "\"" + key + "\"";
   int keyPos = StringFind(json, needle);
   if(keyPos < 0)
      return(false);

   int colonPos = StringFind(json, ":", keyPos + StringLen(needle));
   if(colonPos < 0)
      return(false);

   int len = StringLen(json);
   int i = colonPos + 1;
   while(i < len && StringGetCharacter(json, i) == ' ')
      i++;
   int start = i;

   while(i < len)
     {
      ushort ch = StringGetCharacter(json, i);
      bool isNumChar = (ch >= '0' && ch <= '9') || ch == '-' || ch == '+' ||
                        ch == '.' || ch == 'e' || ch == 'E';
      if(!isNumChar)
         break;
      i++;
     }
   if(i == start)
      return(false);

   out = StringToDouble(StringSubstr(json, start, i - start));
   return(true);
  }

#endif // KV_AI_JSON_LITE_MQH
