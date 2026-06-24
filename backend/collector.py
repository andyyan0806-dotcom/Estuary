"""
Data collector: fetches water quality from Korean Public Data Portal
and upserts into Supabase. Run once or via scheduler.py.

API: 환경부 수질측정망 실시간 수질정보 (WaterQuality real-time API)
Portal: https://www.data.go.kr/data/15001225/openapi.do
"""

import os
import requests
import pandas as pd
from datetime import datetime, timezone
from dotenv import load_dotenv
from supabase import create_client, Client
from risk_logic import compute_risk

load_dotenv()

SUPABASE_URL = os.environ["SUPABASE_URL"]
SUPABASE_KEY = os.environ["SUPABASE_SERVICE_KEY"]
API_KEY      = os.environ["PUBLIC_DATA_API_KEY"]

# Real-time water quality API endpoint
WQ_API_URL = "https://apis.data.go.kr/B500001/waterQualityObsStation/getWaterQualityObs"

# Map our station IDs to the government measurement point codes
# (fill in actual codes from data.go.kr after registering)
STATION_MAPPING = {
    "HAN_EST_01": "3008680",  # 전류리 (placeholder)
    "HAN_EST_02": "3008690",
    "HAN_EST_03": "3008700",
    "ICN_CST_01": "5000050",
    "ICN_CST_02": "5000060",
    "ICN_CST_03": "5000070",
    "ICN_CST_04": "5000080",
}


def fetch_station_data(obs_code: str) -> dict | None:
    """Fetch latest measurement for one station from the public API."""
    params = {
        "serviceKey": API_KEY,
        "obsCode":    obs_code,
        "numOfRows":  1,
        "pageNo":     1,
        "_type":      "json",
    }
    try:
        resp = requests.get(WQ_API_URL, params=params, timeout=10)
        resp.raise_for_status()
        items = resp.json().get("response", {}).get("body", {}).get("items", {}).get("item", [])
        if isinstance(items, dict):
            items = [items]
        return items[0] if items else None
    except Exception as e:
        print(f"[collector] API error for {obs_code}: {e}")
        return None


def parse_measurement(raw: dict) -> dict:
    """Normalize API response into our measurement schema."""
    def _float(v):
        try:
            return float(v)
        except (TypeError, ValueError):
            return None

    return {
        "water_temp":   _float(raw.get("wt")),
        "ph":           _float(raw.get("ph")),
        "total_p":      _float(raw.get("tp")),
        "dissolved_o2": _float(raw.get("do")),
        "ts":           datetime.now(timezone.utc).isoformat(),
    }


def run_collection():
    supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)
    print(f"[collector] Starting collection run at {datetime.now(timezone.utc)}")

    for station_id, obs_code in STATION_MAPPING.items():
        raw = fetch_station_data(obs_code)
        if raw is None:
            print(f"[collector] No data for {station_id}, skipping.")
            continue

        m = parse_measurement(raw)
        m["station_id"] = station_id

        # Insert measurement
        supabase.table("measurements").insert(m).execute()

        # Compute and upsert risk level
        level, reason = compute_risk(
            m["water_temp"], m["ph"], m["total_p"], m["dissolved_o2"]
        )
        supabase.table("risk_status").insert({
            "station_id": station_id,
            "ts":         m["ts"],
            "level":      level,
            "reason":     reason,
        }).execute()

        print(f"[collector] {station_id} → {level} ({reason})")

    print("[collector] Done.")


if __name__ == "__main__":
    run_collection()
