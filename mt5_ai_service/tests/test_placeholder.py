from kv_ai_service import SCHEMA_VERSION


def test_schema_version_defined():
    assert SCHEMA_VERSION == "1.0"
