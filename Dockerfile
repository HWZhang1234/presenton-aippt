# Use Ubuntu 24.04 base for GLIBC 2.39 (required by presentation-export v0.2.2)
FROM ubuntu:24.04 AS fastapi-builder

# Install Python 3.12 (default in Ubuntu 24.04) and build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 \
    python3-venv \
    python3-pip \
    ca-certificates \
    gcc \
    g++ \
    python3-dev \
    libffi-dev \
    libjpeg-dev \
    libpng-dev \
    zlib1g-dev \
    libxml2-dev \
    libxslt1-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app/servers/fastapi

ENV UV_COMPILE_BYTECODE=1 \
    UV_LINK_MODE=copy

# Create venv and install uv inside it (avoid PEP 668 restrictions)
RUN python3 -m venv /opt/venv \
    && /opt/venv/bin/pip install --no-cache-dir uv

COPY electron/servers/fastapi/pyproject.toml electron/servers/fastapi/uv.lock ./
RUN --mount=type=cache,target=/root/.cache/uv \
    /opt/venv/bin/uv export --frozen --no-dev --no-emit-project -o /tmp/requirements.txt \
    && /opt/venv/bin/uv pip install --no-verify-hashes --python /opt/venv/bin/python -r /tmp/requirements.txt

COPY electron/servers/fastapi /app/servers/fastapi
RUN --mount=type=cache,target=/root/.cache/uv \
    /opt/venv/bin/uv pip install --python /opt/venv/bin/python --no-deps .
# mem0/spaCy BM25 lemmatization loads en_core_web_sm at runtime; spaCy tries pip to
# download it otherwise. Runtime image has no pip in PATH (--without-pip venv).
RUN --mount=type=cache,target=/root/.cache/uv \
    /opt/venv/bin/uv pip install --python /opt/venv/bin/python \
    "https://github.com/explosion/spacy-models/releases/download/en_core_web_sm-3.8.0/en_core_web_sm-3.8.0-py3-none-any.whl"
RUN --mount=type=cache,target=/root/.cache \
    /opt/venv/bin/python scripts/warm_fastembed_cache.py


FROM node:20-bookworm-slim AS nextjs-builder

WORKDIR /app/servers/nextjs

ENV NEXT_TELEMETRY_DISABLED=1
ENV BUILD_TARGET=docker
ENV NODE_TLS_REJECT_UNAUTHORIZED=0
ENV NEXT_FONT_GOOGLE_SKIP_VALIDATING=true
ENV PUPPETEER_EXECUTABLE_PATH=/usr/bin/google-chrome-stable

COPY electron/servers/nextjs/package.json electron/servers/nextjs/package-lock.json ./
RUN --mount=type=cache,target=/root/.npm \
    npm ci

COPY electron/servers/nextjs /app/servers/nextjs

# Temporarily patch Google Fonts for Docker build using Node.js
RUN node -e "\
const fs = require('fs'); \
const content = fs.readFileSync('app/layout.tsx', 'utf8'); \
const patched = content \
  .replace('import { Syne, Unbounded } from \"next/font/google\";', '// import { Syne, Unbounded } from \"next/font/google\";') \
  .replace(/const syne = Syne\({[^}]+}\);/s, '// const syne = Syne({ ... });') \
  .replace(/const unbounded = Unbounded\({[^}]+}\);/s, '// const unbounded = Unbounded({ ... });') \
  .replace('\${unbounded.variable}', '') \
  .replace('\${syne.variable}', ''); \
fs.writeFileSync('app/layout.tsx', patched);"

RUN npm run build \
    && rm -rf .next-build/cache


FROM node:20-bookworm-slim AS assets-builder

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates unzip \
    && rm -rf /var/lib/apt/lists/*

COPY package.json /app/

RUN mkdir -p /app/document-extraction-liteparse \
    && npm --prefix /app/document-extraction-liteparse init -y \
    && npm --prefix /app/document-extraction-liteparse install @llamaindex/liteparse@1.4.0 --omit=dev

COPY electron/resources/document-extraction/liteparse_runner.mjs /app/document-extraction-liteparse/liteparse_runner.mjs
COPY scripts/sync-presentation-export.cjs /app/scripts/sync-presentation-export.cjs
# Use pre-downloaded zip to avoid unreliable network access inside Docker build
COPY scripts/export-Linux-X64.zip /tmp/export-Linux-X64.zip
# Bundled export still loads @img/sharp-* native addons from node_modules (not inlined).
RUN unzip -o /tmp/export-Linux-X64.zip -d /app/presentation-export \
    && rm /tmp/export-Linux-X64.zip \
    && chmod +x /app/presentation-export/py/convert-linux-x64 \
    && cd /app/presentation-export \
    && npm init -y \
    && npm install "sharp@^0.34.5" --include=optional --omit=dev --no-fund --no-audit --no-package-lock


# Use Ubuntu 24.04 for GLIBC 2.39 support
FROM ubuntu:24.04 AS runtime

# Install Python 3.12 (default in Ubuntu 24.04)
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 \
    python3-venv \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

ARG INSTALL_TESSERACT=true
ARG INSTALL_LIBREOFFICE=true
ARG HTTP_PROXY=http://secure-proxy2.qualcomm.com:9090
ARG HTTPS_PROXY=http://secure-proxy2.qualcomm.com:9090

# LiteParse uses Node + @llamaindex/liteparse (same runner as Electron); OCR uses Tesseract.
ENV APP_DATA_DIRECTORY=/app_data \
    TEMP_DIRECTORY=/tmp/presenton \
    EXPORT_PACKAGE_ROOT=/app/presentation-export \
    EXPORT_RUNTIME_DIR=/app/presentation-export \
    BUILT_PYTHON_MODULE_PATH=/app/presentation-export/py/convert-linux-x64 \
    PRESENTON_APP_ROOT=/app \
    PATH="/opt/venv/bin:${PATH}" \
    NODE_ENV=production \
    START_OLLAMA=false \
    HTTP_PROXY=${HTTP_PROXY} \
    HTTPS_PROXY=${HTTPS_PROXY} \
    http_proxy=${HTTP_PROXY} \
    https_proxy=${HTTPS_PROXY} \
    NO_PROXY=localhost,127.0.0.1,::1,0.0.0.0 \
    no_proxy=localhost,127.0.0.1,::1,0.0.0.0 \
    PUPPETEER_EXECUTABLE_PATH=/usr/bin/google-chrome-stable

# 配置 apt 使用代理并设置超时重试
RUN echo "Acquire::http::Proxy \"${HTTP_PROXY}\";" > /etc/apt/apt.conf.d/proxy.conf && \
    echo "Acquire::https::Proxy \"${HTTPS_PROXY}\";" >> /etc/apt/apt.conf.d/proxy.conf && \
    echo "Acquire::http::Timeout \"300\";" >> /etc/apt/apt.conf.d/proxy.conf && \
    echo "Acquire::https::Timeout \"300\";" >> /etc/apt/apt.conf.d/proxy.conf && \
    echo "Acquire::Retries \"3\";" >> /etc/apt/apt.conf.d/proxy.conf

# 分批安装软件包，提高稳定性
# 第一批：基础工具和 Chrome 依赖
RUN apt-get update && apt-get install -y --no-install-recommends --fix-missing \
    ca-certificates \
    curl \
    nginx \
    fontconfig \
    imagemagick \
    zstd \
    wget \
    gnupg

# 第二批：安装 Chrome 和 Puppeteer 依赖
RUN wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | gpg --dearmor -o /usr/share/keyrings/googlechrome-linux-keyring.gpg \
    && sh -c 'echo "deb [arch=amd64 signed-by=/usr/share/keyrings/googlechrome-linux-keyring.gpg] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list' \
    && apt-get update \
    && apt-get install -y --no-install-recommends --fix-missing \
    google-chrome-stable \
    fonts-ipafont-gothic \
    fonts-wqy-zenhei \
    fonts-thai-tlwg \
    fonts-kacst \
    fonts-freefont-ttf \
    libxss1 \
    libxtst6 \
    libgbm1 \
    libnss3 \
    libasound2t64 \
    libatk-bridge2.0-0 \
    libgtk-3-0 \
    libglib2.0-0

# 第二批：安装 LibreOffice（大包）
RUN if [ "$INSTALL_LIBREOFFICE" = "true" ]; then \
        apt-get install -y --no-install-recommends --fix-missing libreoffice; \
    fi

# 第三批：安装 Tesseract OCR
RUN if [ "$INSTALL_TESSERACT" = "true" ]; then \
        apt-get install -y --no-install-recommends --fix-missing \
        tesseract-ocr \
        tesseract-ocr-eng; \
    fi

# Install Node.js 20 using NodeSource repository
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y --no-install-recommends nodejs

# Clean up
RUN rm -rf /var/lib/apt/lists/*

RUN mkdir -p /app/scripts /app/servers/fastapi /app/servers/nextjs

COPY --from=fastapi-builder /opt/venv /opt/venv
COPY --from=fastapi-builder /app/servers/fastapi /app/servers/fastapi

COPY --from=assets-builder /app/package.json /app/package.json
COPY --from=assets-builder /app/document-extraction-liteparse /app/document-extraction-liteparse
COPY --from=assets-builder /app/presentation-export /app/presentation-export
COPY --from=assets-builder /app/scripts/sync-presentation-export.cjs /app/scripts/sync-presentation-export.cjs

COPY --from=nextjs-builder /app/servers/nextjs/.next-build/standalone/ /app/servers/nextjs/
COPY --from=nextjs-builder /app/servers/nextjs/public /app/servers/nextjs/public
COPY --from=nextjs-builder /app/servers/nextjs/.next-build/static /app/servers/nextjs/.next-build/static

COPY start.js LICENSE NOTICE ./
COPY nginx.conf /etc/nginx/nginx.conf

EXPOSE 80
CMD ["node", "/app/start.js"]
