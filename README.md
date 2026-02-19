# docker-unoserver

[unoserver](https://github.com/unoconv/unoserver) の Docker 構成です。
LibreOffice ベースの HTTP サーバーで、DOCX・XLSX・PPTX などのドキュメントを PDF 等の形式に変換します。

## 前提条件

- Docker
- Docker Compose

## 使い方

### 起動

```bash
docker compose up -d
```

初回はイメージのビルドが自動で行われます。ビルドには数分かかります。

### ログの確認

```bash
docker compose logs -f
```

### 停止

```bash
docker compose down
```

### イメージの再ビルド

`Dockerfile` を変更した場合は `--build` オプションで再ビルドします。

```bash
docker compose up -d --build
```

## 変換リクエスト

サーバーはポート `2003` で待ち受けます。`unoconvert` コマンド経由で変換できます。

```bash
# unoconvert のインストール（ホスト側）
pip install unoserver

# DOCX を PDF に変換
unoconvert --host 127.0.0.1 --port 2003 input.docx output.pdf
```

curl で直接 HTTP リクエストを送ることも可能です。

```bash
curl --form "file=@input.docx" http://localhost:2003/request?convert-to=pdf -o output.pdf
```

## テスト

サーバーが起動している状態で以下を実行します。

```bash
docker compose up -d

uv run pytest tests/
```

`uv run` は初回実行時に依存パッケージを自動でインストールします。
サーバーが起動していない場合はテストはスキップされます。

## ポート

| ポート | 用途 |
|--------|------|
| 2003   | unoserver HTTP API |
