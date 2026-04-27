---
description: "Writing Python tests with pytest: fixtures, parametrize, mock / monkeypatch, async tests with pytest-asyncio / anyio, and focused test runs. Covers unittest interop too."
---

# Python Testing with pytest

Use pytest as the default for new Python projects. `unittest.TestCase` tests still run under pytest, so legacy tests don't need rewriting — but new tests should use plain functions + fixtures.

## Basic structure

```python
# tests/test_auth.py
import pytest
from myapp.auth import login, AuthError

def test_login_succeeds_with_valid_credentials():
    result = login(user="test", password="correct")
    assert result.is_authenticated

def test_login_fails_with_wrong_password():
    with pytest.raises(AuthError, match="invalid credentials"):
        login(user="test", password="wrong")
```

File naming: `test_*.py` or `*_test.py`. Functions: `test_*`. Classes: `Test*` with methods `test_*`.

## Fixtures

```python
import pytest
from myapp.database import Database

@pytest.fixture
def db():
    """In-memory DB, fresh per test."""
    d = Database(":memory:")
    d.migrate()
    yield d
    d.close()

def test_insert_then_fetch(db):
    db.insert({"name": "alice"})
    assert db.fetch("alice") is not None
```

Scope controls teardown frequency: `function` (default), `class`, `module`, `session`.

```python
@pytest.fixture(scope="session")
def shared_client():
    with httpx.Client() as c:
        yield c
```

## Parametrize

```python
@pytest.mark.parametrize(("email", "valid"), [
    ("valid@email.com", True),
    ("notanemail", False),
    ("@missing.com", False),
])
def test_email_validation(email, valid):
    assert is_valid_email(email) == valid
```

Multiple parametrize decorators multiply: N × M test cases.

## Mocking — prefer dependency injection, fall back to monkeypatch/mock

```python
# Preferred — inject a fake
def test_uses_payment_gateway():
    fake = FakePaymentGateway()
    svc = CheckoutService(gateway=fake)
    svc.process(...)
    assert fake.charges == [99.00]

# When you can't inject (module-level imports, hard-coded clients):
def test_sends_email(monkeypatch):
    sent = []
    monkeypatch.setattr("myapp.mailer.smtplib.SMTP", lambda *a, **k: FakeSMTP(sent))
    send_welcome_email("alice@example.com")
    assert len(sent) == 1

# Standard-lib mock for method-level replacement:
from unittest.mock import patch

@patch("myapp.external.fetch")
def test_retries_on_timeout(mock_fetch):
    mock_fetch.side_effect = [TimeoutError(), {"ok": True}]
    assert robust_fetch("url") == {"ok": True}
    assert mock_fetch.call_count == 2
```

`monkeypatch` is scoped to the test and auto-reverts. `patch` (as decorator or context manager) is also scoped. Never leave a patched attribute bleeding across tests.

## Async tests

```python
# pytest-asyncio
import pytest
import httpx

@pytest.mark.asyncio
async def test_async_fetch():
    async with httpx.AsyncClient() as c:
        response = await c.get("https://example.com/healthz")
    assert response.status_code == 200
```

For `anyio` (supports both asyncio and trio), use `@pytest.mark.anyio` instead.

## Temporary directories and files

```python
def test_writes_config(tmp_path):
    config_file = tmp_path / "config.yaml"
    write_config(config_file, key="value")
    assert config_file.read_text().startswith("key:")
```

`tmp_path` (pathlib) and `tmp_path_factory` are built-in fixtures. Never leave `/tmp/` garbage behind.

## Focused test runs

```bash
pytest tests/test_auth.py                       # one file
pytest tests/test_auth.py::test_login_succeeds  # one test
pytest -k 'login and not wrong'                 # name-pattern selection
pytest -m slow                                   # by marker
pytest -x                                        # stop on first failure
pytest --lf                                      # re-run only last failures
pytest --ff                                      # failed tests first, then the rest
```

For TDD loops, combine `-x --ff` with `pytest-watch` (`ptw`) for auto-rerun on file change.

## Markers — separate slow / integration / e2e

```python
# pyproject.toml
# [tool.pytest.ini_options]
# markers = [
#     "slow: tests that take >1s",
#     "integration: requires a running service",
#     "e2e: full end-to-end flows",
# ]

@pytest.mark.slow
@pytest.mark.integration
def test_database_migration_end_to_end(postgres_container):
    ...
```

Then skip them by default:
```bash
pytest -m "not (slow or integration or e2e)"    # fast unit tests only
pytest -m integration                           # integration subset
```

## Coverage inside tests

```bash
pytest --cov=src --cov-report=term-missing
pytest --cov=src --cov-branch              # include branch coverage
```

See `coverage-audit` for interpreting results.

## unittest interop

Old `unittest.TestCase` tests run unchanged under pytest. Mix them freely — but do not write **new** tests as `TestCase` subclasses. Function-style fixtures + parametrize are cleaner.
