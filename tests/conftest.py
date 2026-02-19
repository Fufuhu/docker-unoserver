import xmlrpc.client

import pytest

XMLRPC_URL = "http://localhost:2003"


@pytest.fixture(scope="session", autouse=True)
def server_running():
    try:
        with xmlrpc.client.ServerProxy(XMLRPC_URL, allow_none=True) as proxy:
            proxy.info()
    except ConnectionRefusedError:
        pytest.skip("unoserver が起動していません。`docker compose up -d` を実行してください。")
