import os
import sqlite3
from flask import Flask, jsonify, request, g
from pathlib import Path
from datetime import datetime

DB_PATH = os.environ.get("DB_PATH", "./data/orders.db")
Path("./data").mkdir(parents=True, exist_ok=True)

app = Flask(__name__)

def get_db():
    db = getattr(g, "_db", None)
    if db is None:
        need_init = not os.path.exists(DB_PATH)
        db = g._db = sqlite3.connect(DB_PATH)
        db.row_factory = sqlite3.Row
        if need_init:
            with app.app_context():
                init_db(db)
    return db

def init_db(db):
    cur = db.cursor()
    cur.execute("""
    CREATE TABLE IF NOT EXISTS orders (
        order_id     INTEGER PRIMARY KEY,
        customer_id  INTEGER NOT NULL,
        status       TEXT NOT NULL,
        total_amount REAL NOT NULL,
        currency     TEXT NOT NULL DEFAULT 'USD',
        created_at   TEXT NOT NULL,
        updated_at   TEXT NOT NULL
    );
    """)
    db.commit()
    # seed if empty
    cur.execute("SELECT COUNT(*) AS c FROM orders")
    if cur.fetchone()["c"] == 0:
        now = datetime.utcnow().isoformat() + "Z"
        rows = [
            (1001, 501, "new", 125.50, "USD", now, now),
            (1002, 502, "paid", 59.99, "USD", now, now),
            (1003, 503, "shipped", 210.00, "USD", now, now),
        ]
        cur.executemany("INSERT INTO orders VALUES (?,?,?,?,?,?,?)", rows)
        db.commit()

@app.teardown_appcontext
def close_db(exception):
    db = getattr(g, "_db", None)
    if db is not None:
        db.close()

@app.get("/health")
def health():
    try:
        db = get_db()
        cur = db.cursor()
        cur.execute("SELECT 1")
        cur.fetchone()
        return jsonify(status="ok"), 200
    except Exception as e:
        return jsonify(status="degraded", error=str(e)), 503

@app.get("/")
def root():
    return jsonify(service="orders-api", endpoints=["/health", "/orders"]), 200

@app.get("/orders")
def list_orders():
    status = request.args.get("status")
    limit = int(request.args.get("limit", "50"))
    offset = int(request.args.get("offset", "0"))
    db = get_db()
    cur = db.cursor()
    if status:
        cur.execute("SELECT * FROM orders WHERE status=? ORDER BY order_id LIMIT ? OFFSET ?", (status, limit, offset))
    else:
        cur.execute("SELECT * FROM orders ORDER BY order_id LIMIT ? OFFSET ?", (limit, offset))
    rows = [dict(r) for r in cur.fetchall()]
    return jsonify(rows), 200

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080, debug=True)



