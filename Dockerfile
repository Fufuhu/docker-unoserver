# ---- Builder stage ----
# LibreOffice 層と分離することで unoserver のバージョン変更時に
# 大きな LibreOffice 層のキャッシュを無効化しない。
# pip はこのステージにのみ存在し、ランタイムイメージには含まれない。
FROM debian:bookworm-slim AS builder

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        python3 \
        python3-pip \
    && pip3 install --no-cache-dir --break-system-packages unoserver \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*


# ---- Runtime stage ----
FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive

# --- パッケージインストール ---
# - apt-get upgrade: Debian セキュリティリポジトリから利用可能な最新パッチを適用
# - tini: PID 1 として動作する軽量 init。ゾンビプロセスの刈り取りと
#         SIGTERM の子プロセスへの転送（グレースフルシャットダウン）を担う
RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y --no-install-recommends \
        libreoffice-writer \
        libreoffice-calc \
        libreoffice-impress \
        libreoffice-draw \
        python3 \
        python3-uno \
        fonts-liberation \
        fonts-noto-cjk \
        tini \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Builder ステージから unoserver の Python パッケージとエントリポイントをコピー
# debian:bookworm-slim の Python バージョンは 3.11
COPY --from=builder /usr/local/lib/python3.11/dist-packages /usr/local/lib/python3.11/dist-packages
COPY --from=builder /usr/local/bin/unoserver \
                    /usr/local/bin/unoconvert \
                    /usr/local/bin/unocompare \
                    /usr/local/bin/unoping \
                    /usr/local/bin/

# --- setuid / setgid ビットの除去 ---
# コンテナ内のバイナリ（ping, su, newgrp 等）に付与された setuid/setgid ビットを除去する。
# これらのビットを悪用した権限昇格経路を排除する。
# unoserver の動作に setuid/setgid バイナリは不要であるため機能への影響はない。
RUN find / -xdev -perm /6000 -type f -exec chmod a-s {} + 2>/dev/null || true

# --- 非 root ユーザーの作成 ---
# root での実行を避けるため専用ユーザーを作成する。
# コンテナ脱出が発生した場合のホストへの影響範囲を最小化する。
# - UID 1001: 固定 UID により外部ボリューム等でのパーミッション管理を容易にする
# - /sbin/nologin: インタラクティブログインを不可にする
# - --no-log-init: /var/log/lastlog 等コンテナ不要なログファイルへの書き込みを防止
RUN useradd --uid 1001 --create-home --shell /sbin/nologin --no-log-init unoserver

WORKDIR /home/unoserver

# 以降のすべての命令（HEALTHCHECK の CMD を含む）は unoserver ユーザーで実行される
USER unoserver

EXPOSE 2003

HEALTHCHECK --interval=15s --timeout=15s --start-period=120s --retries=5 \
    CMD python3 -c "import xmlrpc.client; xmlrpc.client.ServerProxy('http://localhost:2003').info()"

# tini を PID 1 として起動し、unoserver を子プロセスとして実行する
ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["python3", "-m", "unoserver.server", "--interface", "0.0.0.0"]
