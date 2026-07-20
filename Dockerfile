FROM python:3.11-slim

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    BROWSER_HEADLESS=0

# System deps: Xvfb (headed browser under headless container), browser libs, ffmpeg
RUN apt-get update && apt-get install -y --no-install-recommends \
        xvfb \
        xauth \
        libnss3 libnspr4 libatk1.0-0 libatk-bridge2.0-0 libcups2 \
        libdrm2 libxkbcommon0 libgbm1 libasound2 libxcomposite1 \
        libxdamage1 libxrandr2 libxfixes3 libpango-1.0-0 \
        libgtk-3-0 libdbus-glib-1-2 libxt6 \
        fonts-liberation fonts-noto-color-emoji \
        ffmpeg curl ca-certificates wget \
    && rm -rf /var/lib/apt/lists/*

# Python deps (waguri requirements + cloakbrowser)
RUN pip install --no-cache-dir \
        cloakbrowser \
        fastapi uvicorn pydantic \
        pillow onnxruntime opencv-python-headless numpy \
        httpx

# Pre-download CloakBrowser Chromium binary at build time (so runtime launch is instant)
RUN python -c "from cloakbrowser import ensure_binary; ensure_binary()" || \
    echo "cloakbrowser binary pre-download failed — will download at runtime"

WORKDIR /app

# Copy SEMUA file waguri apa adanya
COPY . .

# ONNX model sudah ada di recaptcha/models/recaptcha_cls_s.onnx
# apikey.txt sudah ada di common/apikey.txt

ENV PORT=8000
EXPOSE 8000

# Xvfb wrapper (headed browser under headless container)
CMD ["sh", "-c", "Xvfb :99 -screen 0 1280x720x24 -nolisten tcp & sleep 1 && export DISPLAY=:99 && exec python server.py"]
