import pytest
import requests

BASE_URL = "http://localhost:2003"


@pytest.fixture(scope="session", autouse=True)
def server_running():
    try:
        requests.get(BASE_URL, timeout=5)
    except requests.exceptions.ConnectionError:
        pytest.skip("unoserver が起動していません。`docker compose up -d` を実行してください。")
