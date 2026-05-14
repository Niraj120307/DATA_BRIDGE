from fastapi import FastAPI, File, UploadFile
from fastapi.middleware.cors import CORSMiddleware
import pytesseract
from PIL import Image
import io
from groq import Groq
import json
import sqlite3
import time

app = FastAPI()

# ── Config ────────────────────────────────────
import platform
if platform.system() == 'Windows':
    pytesseract.pytesseract.tesseract_cmd = r'C:\Program Files\Tesseract-OCR\tesseract.exe'
import os
GROQ_API_KEY = os.environ.get("GROQ_API_KEY", "")
DB_PATH = "databridge.db"

# ── CORS ──────────────────────────────────────
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# ── DB helpers ────────────────────────────────
def get_db():
    return sqlite3.connect(DB_PATH)

def get_all_tables():
    conn = get_db()
    cursor = conn.cursor()
    cursor.execute("SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE '\\_%' AND name != 'sqlite_sequence'")
    tables = [row[0] for row in cursor.fetchall()]
    conn.close()
    return tables

def get_table_data(table_name):
    conn = get_db()
    cursor = conn.cursor()
    cursor.execute(f"SELECT * FROM {table_name}")
    columns = [desc[0] for desc in cursor.description]
    rows = cursor.fetchall()
    conn.close()
    return columns, rows

def log_analytics(event_type, details):
    conn = get_db()
    cursor = conn.cursor()
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS _analytics (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            event_type TEXT,
            details TEXT,
            timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
        )
    """)
    cursor.execute(
        "INSERT INTO _analytics (event_type, details) VALUES (?, ?)",
        (event_type, json.dumps(details))
    )
    conn.commit()
    conn.close()

# ── Health check ──────────────────────────────
@app.get("/health")
def health():
    return {"status": "alive", "message": "DataBridge backend running"}

# ── OCR: Extract text from image ──────────────
@app.post("/extract/image")
async def extract_image(file: UploadFile = File(...)):
    start = time.time()
    try:
        image_bytes = await file.read()
        image = Image.open(io.BytesIO(image_bytes))
        extracted_text = pytesseract.image_to_string(
            image, config='--psm 6 --oem 3').strip()
        elapsed = round(time.time() - start, 2)
        log_analytics("extraction", {
            "source": "image",
            "processing_time": elapsed,
            "text_length": len(extracted_text)
        })
        return {
            "success": True,
            "extracted_text": extracted_text if extracted_text else "No text found in image",
            "source": "tesseract",
            "processing_time": elapsed,
        }
    except Exception as e:
        return {"success": False, "error": str(e), "extracted_text": ""}

# ── Voice: Transcribe audio via Groq Whisper ──
@app.post("/extract/voice")
async def extract_voice(file: UploadFile = File(...)):
    start = time.time()
    try:
        audio_bytes = await file.read()
        client = Groq(api_key=GROQ_API_KEY)
        transcription = client.audio.transcriptions.create(
            file=(file.filename, audio_bytes),
            model="whisper-large-v3",
            response_format="text"
        )
        elapsed = round(time.time() - start, 2)
        log_analytics("extraction", {
            "source": "voice",
            "processing_time": elapsed,
            "text_length": len(transcription)
        })
        return {
            "success": True,
            "extracted_text": transcription,
            "source": "groq_whisper",
            "processing_time": elapsed,
        }
    except Exception as e:
        return {"success": False, "error": str(e), "extracted_text": ""}

# ── Document: Extract text from PDF/TXT ───────
@app.post("/extract/document")
async def extract_document(file: UploadFile = File(...)):
    start = time.time()
    try:
        file_bytes = await file.read()
        filename = file.filename.lower()
        if filename.endswith('.pdf'):
            import PyPDF2
            reader = PyPDF2.PdfReader(io.BytesIO(file_bytes))
            text = ""
            for page in reader.pages:
                text += page.extract_text() + "\n"
        else:
            text = file_bytes.decode('utf-8', errors='ignore')
        elapsed = round(time.time() - start, 2)
        log_analytics("extraction", {
            "source": "document",
            "processing_time": elapsed,
            "text_length": len(text)
        })
        return {
            "success": True,
            "extracted_text": text.strip(),
            "source": "document",
            "processing_time": elapsed,
        }
    except Exception as e:
        return {"success": False, "error": str(e), "extracted_text": ""}

# ── Spreadsheet: Extract and save all rows ────
@app.post("/extract/spreadsheet")
async def extract_spreadsheet(file: UploadFile = File(...)):
    start = time.time()
    try:
        import pandas as pd
        file_bytes = await file.read()
        filename = file.filename.lower()
        if filename.endswith('.csv'):
            df = pd.read_csv(io.BytesIO(file_bytes))
        else:
            df = pd.read_excel(io.BytesIO(file_bytes))

        df.columns = [c.lower().replace(' ', '_') for c in df.columns]
        table_name = file.filename.split('.')[0].lower().replace(' ', '_')
        conn = get_db()
        cursor = conn.cursor()

        col_defs = []
        for col in df.columns:
            dtype = 'INTEGER' if str(df[col].dtype) in ['int64', 'float64'] else 'TEXT'
            col_defs.append(f"{col} {dtype}")
        cursor.execute(f"CREATE TABLE IF NOT EXISTS {table_name} ({', '.join(col_defs)})")

        for _, row in df.iterrows():
            placeholders = ', '.join(['?' for _ in df.columns])
            values = tuple(str(v) for v in row.values)
            cursor.execute(
                f"INSERT INTO {table_name} ({', '.join(df.columns)}) VALUES ({placeholders})",
                values)

        conn.commit()
        conn.close()
        elapsed = round(time.time() - start, 2)
        log_analytics("extraction", {
            "source": "spreadsheet",
            "processing_time": elapsed,
            "rows": len(df)
        })
        text = df.to_string(index=False)
        return {
            "success": True,
            "extracted_text": text.strip(),
            "source": "spreadsheet",
            "table_name": table_name,
            "rows_saved": len(df),
            "already_saved": True,
            "processing_time": elapsed,
        }
    except Exception as e:
        return {"success": False, "error": str(e), "extracted_text": ""}

# ── Schema generation via Groq ────────────────
@app.post("/schema/generate")
async def generate_schema(data: dict):
    start = time.time()
    text = data.get("text", "")
    if not text:
        return {"success": False, "error": "No text provided"}
    try:
        client = Groq(api_key=GROQ_API_KEY)
        prompt = (
            "Analyze this extracted text and return a JSON schema for a database table.\n"
            "Return ONLY a JSON object, nothing else. No explanation, no markdown, no backticks.\n"
            "Format:\n"
            "{\n"
            '  "table_name": "snake_case_name",\n'
            '  "fields": [\n'
            '    {\n'
            '      "name": "field_name",\n'
            '      "type": "TEXT|INTEGER|REAL",\n'
            '      "value": "extracted value or empty string",\n'
            '      "confidence": 95,\n'
            '      "valid": true,\n'
            '      "reason": ""\n'
            '    }\n'
            '  ]\n'
            '}\n\n'
            'Rules:\n'
            '- confidence: 0-100 based on how clearly the value was extracted\n'
            '- valid: false if value seems wrong (marks > 100, negative age, empty required field)\n'
            '- reason: explain why invalid, empty string if valid\n\n'
            'Text to analyze:\n'
            + text
        )
        chat_completion = client.chat.completions.create(
            messages=[
                {
                    "role": "system",
                    "content": "You are a database schema generator. Always respond with valid JSON only. No explanation, no markdown, no backticks."
                },
                {"role": "user", "content": prompt}
            ],
            model="llama-3.3-70b-versatile",
            temperature=0.1,
        )
        raw = chat_completion.choices[0].message.content.strip()
        raw = raw.replace("```json", "").replace("```", "").strip()
        schema = json.loads(raw)
        elapsed = round(time.time() - start, 2)

        # Log anomalies
        fields = schema.get("fields", [])
        for field in fields:
            if not field.get("valid", True):
                log_analytics("anomaly", {
                    "field": field.get("name"),
                    "value": field.get("value"),
                    "reason": field.get("reason")
                })

        # Calculate avg confidence
        confidences = [f.get("confidence", 100) for f in fields]
        avg_conf = round(sum(confidences) / len(confidences), 1) if confidences else 100

        log_analytics("schema_generation", {
            "processing_time": elapsed,
            "fields_count": len(fields),
            "avg_confidence": avg_conf,
            "anomalies": sum(1 for f in fields if not f.get("valid", True))
        })

        return {"success": True, "schema": schema, "processing_time": elapsed}
    except Exception as e:
        return {"success": False, "error": str(e)}

# ── Save to database ──────────────────────────
@app.post("/data/save")
async def save_data(data: dict):
    schema = data.get("schema", {})
    table_name = schema.get("table_name", "extracted_data")
    fields = schema.get("fields", [])
    if not fields:
        return {"success": False, "error": "No fields to save"}
    try:
        conn = get_db()
        cursor = conn.cursor()
        col_defs = ", ".join([f"{f['name']} {f['type']}" for f in fields])
        # Create table if not exists
        cursor.execute(f"CREATE TABLE IF NOT EXISTS {table_name} ({col_defs})")

        # Add any missing columns (for fusion with new fields)
        cursor.execute(f"PRAGMA table_info({table_name})")
        existing_cols = [row[1] for row in cursor.fetchall()]
        for f in fields:
            if f['name'] not in existing_cols:
                cursor.execute(f"ALTER TABLE {table_name} ADD COLUMN {f['name']} {f['type']}")
        col_names = ", ".join([f["name"] for f in fields])
        placeholders = ", ".join(["?" for _ in fields])
        values = tuple(f.get("value", "") for f in fields)
        cursor.execute(
            f"INSERT INTO {table_name} ({col_names}) VALUES ({placeholders})",
            values)
        conn.commit()
        conn.close()

        # Log accuracy — fields that were valid without editing
        valid_count = sum(1 for f in fields if f.get("valid", True))
        log_analytics("save", {
            "table": table_name,
            "total_fields": len(fields),
            "valid_fields": valid_count,
            "accuracy": round(valid_count / len(fields) * 100, 1) if fields else 100
        })

        return {"success": True, "table": table_name, "message": f"Data saved to {table_name}"}
    except Exception as e:
        return {"success": False, "error": str(e)}

# ── Get all tables ────────────────────────────
@app.get("/database/tables")
def list_tables():
    try:
        tables = get_all_tables()
        result = []
        for table in tables:
            columns, rows = get_table_data(table)
            result.append({
                "name": table,
                "columns": columns,
                "row_count": len(rows)
            })
        return {"success": True, "tables": result}
    except Exception as e:
        return {"success": False, "error": str(e)}

# ── Get table rows ────────────────────────────
@app.get("/database/table/{table_name}")
def get_table(table_name: str):
    try:
        columns, rows = get_table_data(table_name)
        return {
            "success": True,
            "columns": columns,
            "rows": [dict(zip(columns, row)) for row in rows]
        }
    except Exception as e:
        return {"success": False, "error": str(e)}

# ── NL to SQL via Groq ────────────────────────
@app.post("/query/nl")
async def nl_to_sql(data: dict):
    question = data.get("question", "")
    if not question:
        return {"success": False, "error": "No question provided"}
    try:
        tables = get_all_tables()
        if not tables:
            return {"success": False, "error": "No tables in database yet"}

        schema_context = ""
        for table in tables:
            columns, _ = get_table_data(table)
            schema_context += f"Table: {table}, Columns: {', '.join(columns)}\n"

        client = Groq(api_key=GROQ_API_KEY)
        nl_prompt = (
            "Convert this question to a SQLite SQL query.\n"
            "Return only the SQL query, nothing else. No explanation, no backticks.\n\n"
            "Database schema:\n"
            + schema_context
            + "\nQuestion: "
            + question
        )
        chat_completion = client.chat.completions.create(
            messages=[
                {
                    "role": "system",
                    "content": "You are a SQL query generator. Return only the SQL query, nothing else."
                },
                {"role": "user", "content": nl_prompt}
            ],
            model="llama-3.3-70b-versatile",
            temperature=0.1,
        )
        sql = chat_completion.choices[0].message.content.strip()
        sql = sql.replace("```sql", "").replace("```", "").strip()

        conn = get_db()
        cursor = conn.cursor()
        cursor.execute(sql)
        columns = [desc[0] for desc in cursor.description] if cursor.description else []
        rows = cursor.fetchall()
        conn.close()

        return {
            "success": True,
            "sql": sql,
            "columns": columns,
            "rows": [dict(zip(columns, row)) for row in rows]
        }
    except Exception as e:
        return {"success": False, "error": str(e), "sql": ""}

# ── Analytics Summary ─────────────────────────
@app.get("/analytics/summary")
def get_analytics_summary():
    try:
        conn = get_db()
        cursor = conn.cursor()
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS _analytics (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                event_type TEXT,
                details TEXT,
                timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
            )
        """)
        cursor.execute("SELECT event_type, details FROM _analytics")
        rows = cursor.fetchall()
        conn.close()

        total_extractions = 0
        by_source = {}
        confidence_scores = []
        anomalies = 0
        processing_times = []
        accuracy_scores = []

        for event_type, details_str in rows:
            details = json.loads(details_str)
            if event_type == "extraction":
                total_extractions += 1
                source = details.get("source", "unknown")
                by_source[source] = by_source.get(source, 0) + 1
                if "processing_time" in details:
                    processing_times.append(details["processing_time"])
            elif event_type == "schema_generation":
                if "avg_confidence" in details:
                    confidence_scores.append(details["avg_confidence"])
                if "processing_time" in details:
                    processing_times.append(details["processing_time"])
            elif event_type == "anomaly":
                anomalies += 1
            elif event_type == "save":
                if "accuracy" in details:
                    accuracy_scores.append(details["accuracy"])

        return {
            "success": True,
            "total_extractions": total_extractions,
            "by_source": by_source,
            "avg_confidence": round(sum(confidence_scores) / len(confidence_scores), 1) if confidence_scores else 0,
            "anomalies_caught": anomalies,
            "avg_processing_time": round(sum(processing_times) / len(processing_times), 2) if processing_times else 0,
            "avg_accuracy": round(sum(accuracy_scores) / len(accuracy_scores), 1) if accuracy_scores else 0,
        }
    except Exception as e:
        return {"success": False, "error": str(e)}

# ── Analytics Logs ────────────────────────────
@app.get("/analytics/logs")
def get_analytics_logs():
    try:
        conn = get_db()
        cursor = conn.cursor()
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS _analytics (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                event_type TEXT,
                details TEXT,
                timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
            )
        """)
        cursor.execute("SELECT * FROM _analytics ORDER BY timestamp DESC LIMIT 50")
        rows = cursor.fetchall()
        conn.close()
        return {
            "success": True,
            "logs": [
                {
                    "id": r[0],
                    "event_type": r[1],
                    "details": json.loads(r[2]),
                    "timestamp": r[3]
                } for r in rows
            ]
        }
    except Exception as e:
        return {"success": False, "error": str(e)}
    
    # ── Multimodal Fusion ─────────────────────────
@app.post("/fusion/merge")
async def fusion_merge(data: dict):
    try:
        schema1 = data.get("schema1", {})
        schema2 = data.get("schema2", {})
        
        fields1 = {f["name"]: f for f in schema1.get("fields", [])}
        fields2 = {f["name"]: f for f in schema2.get("fields", [])}
        
        merged_fields = []
        all_keys = set(list(fields1.keys()) + list(fields2.keys()))
        
        for key in all_keys:
            f1 = fields1.get(key)
            f2 = fields2.get(key)
            
            if f1 and f2:
                # Both sources have this field — compare values
                val1 = str(f1.get("value", "")).strip().lower()
                val2 = str(f2.get("value", "")).strip().lower()
                conf1 = f1.get("confidence", 100)
                conf2 = f2.get("confidence", 100)
                
                if val1 == val2:
                    # Both agree — boost confidence
                    merged_conf = min(100, int((conf1 + conf2) / 2) + 10)
                    merged_fields.append({
                        "name": key,
                        "type": f1.get("type", "TEXT"),
                        "value": f1.get("value", ""),
                        "confidence": merged_conf,
                        "valid": f1.get("valid", True) and f2.get("valid", True),
                        "reason": f1.get("reason", ""),
                        "fusion": "agreed",
                        "sources": 2
                    })
                else:
                    # Sources disagree — flag for user
                    merged_fields.append({
                        "name": key,
                        "type": f1.get("type", "TEXT"),
                        "value": f1.get("value", ""),
                        "value2": f2.get("value", ""),
                        "confidence": int((conf1 + conf2) / 2),
                        "valid": True,
                        "reason": "",
                        "fusion": "conflict",
                        "sources": 2
                    })
            elif f1:
                # Only in source 1
                merged_fields.append({**f1, "fusion": "single", "sources": 1})
            elif f2:
                # Only in source 2
                merged_fields.append({**f2, "fusion": "single", "sources": 1})
        
        # Use table name from schema1
        table_name = schema1.get("table_name", schema2.get("table_name", "fused_data"))
        
        # Log fusion event
        agreed = sum(1 for f in merged_fields if f.get("fusion") == "agreed")
        conflicts = sum(1 for f in merged_fields if f.get("fusion") == "conflict")
        log_analytics("fusion", {
            "table": table_name,
            "total_fields": len(merged_fields),
            "agreed_fields": agreed,
            "conflict_fields": conflicts,
            "fusion_score": round(agreed / len(merged_fields) * 100, 1) if merged_fields else 0
        })
        
        return {
            "success": True,
            "schema": {
                "table_name": table_name,
                "fields": merged_fields
            },
            "fusion_score": round(agreed / len(merged_fields) * 100, 1) if merged_fields else 0,
            "agreed": agreed,
            "conflicts": conflicts
        }
    except Exception as e:
        return {"success": False, "error": str(e)}