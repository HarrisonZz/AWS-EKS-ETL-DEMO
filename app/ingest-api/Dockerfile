FROM python:3.11-slim

# 設定環境變數
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

# 設定工作目錄
WORKDIR /app

# 先複製 requirements.txt 以利用 Docker Cache 機制
COPY requirements.txt .

# 安裝依賴套件
RUN pip install --no-cache-dir -r requirements.txt

# 複製其餘程式碼
COPY . .

# 暴露 FastAPI 預設 Port
EXPOSE 8000

# 啟動指令
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]