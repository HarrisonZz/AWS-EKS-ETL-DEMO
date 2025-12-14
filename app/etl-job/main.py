import duckdb
import logging
from datetime import datetime, timezone
import os
from dataclasses import dataclass

# 設定 Logging
logging.basicConfig(level=logging.INFO, format="[%(levelname)s] %(message)s")
logger = logging.getLogger(__name__)

@dataclass
class ETLConfig:
    s3_bucket: str
    process_date: str
    # DevOps 關鍵細節：限制記憶體使用量，模擬在 K8s Pod 運作的情境
    memory_limit: str = "512MB" 
    threads: int = 2
    # 新增：指定暫存目錄，避免塞爆容器 Root FS
    temp_dir: str = "/tmp/duckdb_spill"

class DuckDBPipeline:
    def __init__(self, config: ETLConfig):
        self.config = config
        # 初始化 DuckDB 連線 (In-memory mode)
        self.con = duckdb.connect(config={
            'memory_limit': config.memory_limit,
            'threads': config.threads,
            'temp_directory': config.temp_dir
        })
        self.con.execute(f"SET threads={config.threads};")
        self._setup_aws_auth()

    def _ensure_temp_dir(self):
        os.makedirs(self.config.temp_dir, exist_ok=True)

    def _setup_aws_auth(self):
        """
        自動讀取環境變數 (AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY)
        這符合 12-Factor App 的設定原則
        """
        try:
            self.con.execute("INSTALL httpfs; LOAD httpfs;")
            self.con.execute("CALL load_aws_credentials();")
            # 設定 S3 區域，避免跨區傳輸延遲
            region = os.getenv("AWS_REGION", "ap-northeast-1")
            self.con.execute(f"SET s3_region='{region}';")
        except Exception as e:
            logger.error(f"Failed to setup AWS Auth: {e}")
            raise

    def run(self):
        """
        執行 Extract -> Transform -> Aggregate -> Load
        一次搞定
        """
        logger.info(f"🚀 Starting DuckDB ETL for date: {self.config.process_date}")
        
        input_path = f"s3://{self.config.s3_bucket}/raw/{self.config.process_date}/*.jsonl"
        output_path = f"s3://{self.config.s3_bucket}/curated/{self.config.process_date}/agg-{self.config.process_date}.parquet"

        # 這裡的 SQL 邏輯：
        # 1. read_json_auto: 自動推斷 Schema 讀取 S3
        # 2. WHERE: 過濾負值 (Data Cleaning)
        # 3. GROUP BY: 聚合運算
        # 4. COPY ... TO: 寫回 S3
        
        query = f"""
        COPY (
            SELECT 
                device_id,
                '{self.config.process_date}'::DATE AS date,
                COUNT(*) AS count,
                ROUND(AVG(value), 2) AS avg,
                MIN(value) AS min,
                MAX(value) AS max,
                now() AS processed_at
            FROM read_json_auto('{input_path}', format='newline_delimited')
            WHERE value >= 0 
            GROUP BY device_id
            ORDER BY device_id ASC
        ) TO '{output_path}' (FORMAT 'PARQUET', CODEC 'SNAPPY');
        """

        try:
            logger.info("⏳ Executing aggregation query...")
            self.con.execute(query)
            logger.info(f"✅ ETL Job Completed! Output saved to: {output_path}")

            preview_query = f"""
                SELECT * FROM read_parquet('{output_path}') 
                USING SAMPLE 5 ROWS
            """
            result_preview = self.con.execute(preview_query).fetchall()
            logger.info(f"👀 Result Preview: {result_preview}")

        except Exception as e:
            logger.error(f"❌ ETL Failed: {e}")
            raise

# --- Entry Point ---
if __name__ == "__main__":

    today_str = datetime.now(timezone.utc).strftime("%Y-%m-%d")
    bucket = os.getenv("S3_BUCKET")
    if not bucket:
        raise RuntimeError("S3_BUCKET is required")
    config = ETLConfig(
        s3_bucket=bucket,
        process_date=os.getenv("PROCESS_DATE", today_str),
        memory_limit=os.getenv("DUCKDB_MEMORY_LIMIT", "512MB")
    )
    
    pipeline = DuckDBPipeline(config)
    pipeline.run()