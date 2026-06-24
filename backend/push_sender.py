"""
Push notification sender: queries Supabase for newly red/yellow stations,
finds users with registered points near those stations, and sends FCM push.
"""

import os
import math
from datetime import datetime, timezone, timedelta
from dotenv import load_dotenv
from supabase import create_client, Client
import firebase_admin
from firebase_admin import credentials, messaging

load_dotenv()

SUPABASE_URL = os.environ["SUPABASE_URL"]
SUPABASE_KEY = os.environ["SUPABASE_SERVICE_KEY"]
FIREBASE_CREDS = os.environ.get("FIREBASE_CREDENTIALS_PATH", "./firebase-adminsdk.json")

ALERT_RADIUS_KM = 15.0  # notify users within 15 km of a risky station
LEVEL_LABELS = {"yellow": "주의", "red": "위험"}

_firebase_initialized = False


def _init_firebase():
    global _firebase_initialized
    if not _firebase_initialized:
        cred = credentials.Certificate(FIREBASE_CREDS)
        firebase_admin.initialize_app(cred)
        _firebase_initialized = True


def _haversine_km(lat1, lng1, lat2, lng2) -> float:
    R = 6371.0
    dlat = math.radians(lat2 - lat1)
    dlng = math.radians(lng2 - lng1)
    a = math.sin(dlat / 2) ** 2 + math.cos(math.radians(lat1)) * math.cos(math.radians(lat2)) * math.sin(dlng / 2) ** 2
    return R * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))


def run_push():
    _init_firebase()
    supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

    # Get stations that went red/yellow in the last 2 hours
    cutoff = (datetime.now(timezone.utc) - timedelta(hours=2)).isoformat()
    risky = (
        supabase.table("risk_status")
        .select("station_id, level, reason, ts, stations(lat, lng, name)")
        .in_("level", ["yellow", "red"])
        .gte("ts", cutoff)
        .order("ts", desc=True)
        .execute()
        .data
    )

    if not risky:
        print("[push] No risky stations in the last 2 hours.")
        return

    # Deduplicate to one entry per station (latest)
    seen = {}
    for row in risky:
        sid = row["station_id"]
        if sid not in seen:
            seen[sid] = row
    risky_stations = list(seen.values())

    # Load all user locations + FCM tokens
    locations = supabase.table("user_locations").select("id, user_id, label, lat, lng").execute().data
    tokens_rows = supabase.table("fcm_tokens").select("user_id, token").execute().data
    token_map = {r["user_id"]: r["token"] for r in tokens_rows}

    already_alerted = set()  # (user_id, station_id)

    for station in risky_stations:
        s_lat = station["stations"]["lat"]
        s_lng = station["stations"]["lng"]
        s_name = station["stations"]["name"]
        level = station["level"]

        for loc in locations:
            uid = loc["user_id"]
            pair = (uid, station["station_id"])
            if pair in already_alerted:
                continue

            dist = _haversine_km(loc["lat"], loc["lng"], s_lat, s_lng)
            if dist > ALERT_RADIUS_KM:
                continue

            token = token_map.get(uid)
            if not token:
                continue

            label = LEVEL_LABELS.get(level, level)
            message = messaging.Message(
                notification=messaging.Notification(
                    title=f"[{label}] 수질 이상 감지",
                    body=f"{loc['label']} 인근 {s_name}에서 {label} 수준 부영양화가 감지되었습니다.",
                ),
                data={"station_id": station["station_id"], "level": level},
                token=token,
            )
            try:
                messaging.send(message)
                supabase.table("alerts").insert({
                    "user_id":     uid,
                    "location_id": loc["id"],
                    "station_id":  station["station_id"],
                    "level":       level,
                }).execute()
                already_alerted.add(pair)
                print(f"[push] Sent {level} alert to user {uid} for {s_name}")
            except Exception as e:
                print(f"[push] FCM error for user {uid}: {e}")


if __name__ == "__main__":
    run_push()
