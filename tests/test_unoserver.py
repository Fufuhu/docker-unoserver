import pathlib
import xmlrpc.client

XMLRPC_URL = "http://localhost:2003"
FIXTURES_DIR = pathlib.Path(__file__).parent / "fixtures"


def test_convert_txt_to_pdf():
    """テキストファイルを PDF に変換できることを確認する"""
    with open(FIXTURES_DIR / "sample.txt", "rb") as f:
        indata = f.read()

    with xmlrpc.client.ServerProxy(XMLRPC_URL, allow_none=True) as proxy:
        result = proxy.convert(
            None,                        # inpath
            xmlrpc.client.Binary(indata),  # indata
            None,                        # outpath
            "pdf",                       # convert_to
            None,                        # filtername
            [],                          # filter_options
            True,                        # update_index
            None,                        # infiltername
            None,                        # password
        )

    assert result is not None, "変換結果が空です"
    pdf_bytes = result.data
    assert pdf_bytes[:4] == b"%PDF", "レスポンスが PDF 形式ではありません"
    assert len(pdf_bytes) > 0, "PDF が空です"
