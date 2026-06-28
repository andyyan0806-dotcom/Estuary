"""
SQLite store for registered users (양식장 위치 + 전화번호).
No external dependencies — just stdlib sqlite3.
"""

import sqlite3
import math
import os
from datetime import datetime

DB_PATH = os.path.join(os.path.dirname(__file__), "users.db")


def _connect():
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    return conn


def init_db():
    with _connect() as conn:
        conn.executescript("""
            CREATE TABLE IF NOT EXISTS users (
                kakao_id  TEXT PRIMARY KEY,
                phone     TEXT,
                lat       REAL,
                lng       REAL,
                address   TEXT,
                active    INTEGER DEFAULT 1,
                created_at TEXT
            );

            CREATE TABLE IF NOT EXISTS alert_log (
                id         INTEGER PRIMARY KEY AUTOINCREMENT,
                kakao_id   TEXT,
                station_id TEXT,
                level      TEXT,
                message    TEXT,
                sent_at    TEXT
            );

            -- Pending registration state per user (multi-step chatbot flow)
            CREATE TABLE IF NOT EXISTS reg_state (
                kakao_id TEXT PRIMARY KEY,
                step     TEXT,   -- 'awaiting_location' | 'awaiting_phone'
                lat      REAL,
                lng      REAL,
                address  TEXT
            );
        """)


# ── User CRUD ──────────────────────────────────────────────────────────────────

def upsert_user(kakao_id: str, phone: str, lat: float, lng: float, address: str):
    with _connect() as conn:
        conn.execute("""
            INSERT INTO users (kakao_id, phone, lat, lng, address, active, created_at)
            VALUES (?, ?, ?, ?, ?, 1, ?)
            ON CONFLICT(kakao_id) DO UPDATE SET
                phone=excluded.phone, lat=excluded.lat,
                lng=excluded.lng, address=excluded.address,
                active=1
        """, (kakao_id, phone, lat, lng, address, datetime.now().isoformat()))


def get_active_users():
    with _connect() as conn:
        return [dict(r) for r in conn.execute(
            "SELECT * FROM users WHERE active=1")]


def deactivate_user(kakao_id: str):
    with _connect() as conn:
        conn.execute("UPDATE users SET active=0 WHERE kakao_id=?", (kakao_id,))


# ── Multi-step registration state ─────────────────────────────────────────────

def set_reg_state(kakao_id: str, step: str, lat=None, lng=None, address=None):
    with _connect() as conn:
        conn.execute("""
            INSERT INTO reg_state (kakao_id, step, lat, lng, address)
            VALUES (?, ?, ?, ?, ?)
            ON CONFLICT(kakao_id) DO UPDATE SET
                step=excluded.step,
                lat=COALESCE(excluded.lat, reg_state.lat),
                lng=COALESCE(excluded.lng, reg_state.lng),
                address=COALESCE(excluded.address, reg_state.address)
        """, (kakao_id, step, lat, lng, address))


def get_reg_state(kakao_id: str):
    with _connect() as conn:
        row = conn.execute(
            "SELECT * FROM reg_state WHERE kakao_id=?", (kakao_id,)).fetchone()
        return dict(row) if row else None


def clear_reg_state(kakao_id: str):
    with _connect() as conn:
        conn.execute("DELETE FROM reg_state WHERE kakao_id=?", (kakao_id,))


# ── Alert log ─────────────────────────────────────────────────────────────────

def log_alert(kakao_id: str, station_id: str, level: str, message: str):
    with _connect() as conn:
        conn.execute("""
            INSERT INTO alert_log (kakao_id, station_id, level, message, sent_at)
            VALUES (?, ?, ?, ?, ?)
        """, (kakao_id, station_id, level, message, datetime.now().isoformat()))


def already_alerted_today(kakao_id: str, station_id: str) -> bool:
    """Prevent duplicate alerts: one alert per user per station per day."""
    with _connect() as conn:
        row = conn.execute("""
            SELECT 1 FROM alert_log
            WHERE kakao_id=? AND station_id=?
              AND sent_at >= date('now')
            LIMIT 1
        """, (kakao_id, station_id)).fetchone()
        return row is not None


# ── Geo helper ────────────────────────────────────────────────────────────────

def haversine_km(lat1, lng1, lat2, lng2) -> float:
    R = 6371.0
    dl = math.radians(lng2 - lng1)
    dp = math.radians(lat2 - lat1)
    a = math.sin(dp/2)**2 + math.cos(math.radians(lat1)) * \
        math.cos(math.radians(lat2)) * math.sin(dl/2)**2
    return R * 2 * math.asin(math.sqrt(a))


def nearest_station(user_lat, user_lng, stations: list) -> dict | None:
    """Return the closest station dict (must have lat/lng keys)."""
    if not stations:
        return None
    return min(stations, key=lambda s: haversine_km(
        user_lat, user_lng, s["lat"], s["lng"]))


# Initialise on import
init_db()
