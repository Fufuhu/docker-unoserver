import pathlib
import requests

BASE_URL = "http://localhost:2003"
FIXTURES_DIR = pathlib.Path(__file__).parent / "fixtures"


def test_convert_txt_to_pdf():
    """テキストファイルを PDF に変換できることを確認する"""
    with open(FIXTURES_DIR / "sample.txt", "rb") as f:
        response = requests.post(
            f"{BASE_URL}/request",
            params={"convert-to": "pdf"},
            files={"file": ("sample.txt", f, "text/plain")},
            timeout=60,
        )

    assert response.status_code == 200
    assert response.content[:4] == b"%PDF", "レスポンスが PDF 形式ではありません"
    assert len(response.content) > 0, "PDF が空です"
