# docker-unoserver

[![Dockerfile Lint](https://github.com/Fufuhu/docker-unoserver/actions/workflows/dockerfile-lint.yml/badge.svg)](https://github.com/Fufuhu/docker-unoserver/actions/workflows/dockerfile-lint.yml)
[![Vulnerability Scan](https://github.com/Fufuhu/docker-unoserver/actions/workflows/vulnerability-scan.yml/badge.svg)](https://github.com/Fufuhu/docker-unoserver/actions/workflows/vulnerability-scan.yml)

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

## セキュリティ

### コンテナイメージのセキュリティ強化

本イメージはコンテナセキュリティのベストプラクティスに準拠して構築されています。

#### 非 root ユーザーでの実行

専用の `unoserver` ユーザー（UID: 1001）を作成し、root 権限なしでプロセスを起動します。
コンテナ脱出が発生した場合のホストへの影響範囲を最小化します。

#### tini による適切なシグナルハンドリング

[tini](https://github.com/krallin/tini) を PID 1 として起動します。

- LibreOffice の子プロセスを適切にリープしゾンビプロセスの発生を防止
- `SIGTERM` を unoserver に確実に転送しグレースフルシャットダウンを実現

#### ビルド専用ツールの除去

`python3-pip` はビルド時の unoserver インストールにのみ使用し、同一レイヤー内で削除します。
実行時イメージに pip が残らないため、パッケージの不正インストールリスクを低減します。

#### setuid / setgid ビットの除去

`ping`・`su`・`newgrp` などのシステムバイナリに付与された setuid/setgid ビットを除去します。
これらのビットを悪用した権限昇格経路を排除します。

#### 脆弱性スキャン

Pull Request ごとに [Trivy](https://github.com/aquasecurity/trivy) による脆弱性スキャンを実行し、
結果を PR コメントとして投稿します（`.github/workflows/vulnerability-scan.yml`）。

- 対象深刻度: CRITICAL / HIGH / MEDIUM
- 修正バージョンが存在しない脆弱性は除外（`ignore-unfixed: true`）
- Debian が修正対象外（`will_not_fix`）と判断した CVE は `.trivyignore` で明示的に管理

## ポート

| ポート | 用途 |
|--------|------|
| 2003   | unoserver XMLRPC API |
