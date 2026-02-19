FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive

# --- パッケージインストール ---
# - apt-get upgrade: Debian セキュリティリポジトリから利用可能な最新パッチを適用
# - tini: PID 1 として動作する軽量 init。ゾンビプロセスの刈り取りと
#         SIGTERM の子プロセスへの転送（グレースフルシャットダウン）を担う
# - python3-pip: unoserver のインストールにのみ使用し、同レイヤー内で purge する
#               → pip がランタイムイメージに残らないよう同一 RUN で完結させる
RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y --no-install-recommends \
        libreoffice-writer \
        libreoffice-calc \
        libreoffice-impress \
        libreoffice-draw \
        python3 \
        python3-pip \
        python3-uno \
        fonts-liberation \
        fonts-noto-cjk \
        tini \
    && pip3 install --break-system-packages unoserver \
    && apt-get purge -y python3-pip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# --- setuid / setgid ビットの除去 ---
# コンテナ内のバイナリ（ping, su, newgrp 等）に付与された setuid/setgid ビットを除去する。
# これらのビットを悪用した権限昇格経路を排除する。
# unoserver の動作に setuid/setgid バイナリは不要であるため機能への影響はない。
RUN find / -xdev -perm /6000 -type f -exec chmod a-s {} + 2>/dev/null || true

# --- 非 root ユーザーの作成 ---
# root での実行を避けるため専用ユーザーを作成する。
# コンテナ脱出が発生した場合にホストへの影響範囲を最小化する。
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
