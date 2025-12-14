# 1. 使用 Debian-based 的 slim 版本，確保 DuckDB 安裝順利
FROM python:3.11-slim

# 設定環境變數
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

# 2. 安裝依賴
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

RUN python -c "import duckdb; duckdb.connect().execute('INSTALL httpfs')"

# 3. 複製 ETL 程式碼
COPY . .

# 4. 設定啟動指令
# 因為是 Job，跑完就會自己 Exit，這是正常的
CMD ["python", "etl_job.py"]