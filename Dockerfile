FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    libreoffice-writer \
    libreoffice-calc \
    libreoffice-impress \
    libreoffice-draw \
    python3 \
    python3-pip \
    fonts-liberation \
    fonts-noto-cjk \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN pip3 install --break-system-packages unoserver

EXPOSE 2003

HEALTHCHECK --interval=15s --timeout=15s --start-period=120s --retries=5 \
    CMD python3 -c "import xmlrpc.client; xmlrpc.client.ServerProxy('http://localhost:2003').info()"

CMD ["python3", "-m", "unoserver.server", "--interface", "0.0.0.0"]
