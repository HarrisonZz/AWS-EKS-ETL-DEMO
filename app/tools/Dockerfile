# 1. Base Image: 使用官方 slim 版本 (體積小，安全性高，相容性比 alpine 好)
FROM python:3.11-slim

# 2. 設定環境變數
# PYTHONDONTWRITEBYTECODE=1: 防止 Python 產生 .pyc 文件 (在 container 中不需要)
# PYTHONUNBUFFERED=1: 確保 log 會立即輸出，不會被緩衝 (方便 debug)
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

ENV API_URL="http://localhost:8000/metrics"

# 3. 設定工作目錄
WORKDIR /app

# 4. 建立非 root 使用者 (安全性考量)
RUN adduser --disabled-password --gecos '' appuser

# 5. 安裝依賴 (利用 Layer Caching)
# 先複製 requirements.txt，再執行 install
# 如果您的程式碼改變但依賴沒變，Docker 會直接使用這一層的 cache，大幅加快 build 速度
COPY requirements.txt .

# --no-cache-dir: 不儲存 pip cache，減少 image 大小
RUN pip install --no-cache-dir -r requirements.txt

# 6. 複製程式碼
COPY . .

# 7. 切換到非 root 使用者
USER appuser

# 8. 執行指令 (假設您的主程式檔名是 main.py)
CMD ["python", "fake_client.py"]