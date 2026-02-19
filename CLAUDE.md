# CLAUDE.md

このファイルは、このリポジトリで作業する Claude Code (claude.ai/code) へのガイダンスを提供します。

## プロジェクト概要

このリポジトリは [unoserver](https://github.com/unoconv/unoserver) の Docker 構成です。unoserver は LibreOffice ベースの HTTP サーバーで、DOCX・XLSX・ODP などのドキュメントを PDF 等の形式に変換します。

## 主なコマンド

`Dockerfile` や `docker-compose.yml` が追加された後の一般的なコマンド:

```bash
# Docker イメージをビルド
docker build -t unoserver .

# docker compose で起動
docker compose up -d

# ログを確認
docker compose logs -f

# コンテナを停止
docker compose down
```

> ファイルが追加されたら、このファイルを実際の構成に合わせて更新してください。
