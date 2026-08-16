# kv-ai-service

Local AI signal service for the KV_AI MT5 EA. See `../docs/KV_AI_MT5_EA_SPEC_v1.1.md` (source of truth) for the request/response contract and validation rules.

Run locally:

```
pip install -e ".[dev]"
uvicorn kv_ai_service.app:app --host 127.0.0.1 --port 8765
```

Run tests:

```
pytest -q
```
