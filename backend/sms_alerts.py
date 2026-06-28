"""
SMS 알림 발송 — 등록된 사용자 양식장 근처 측정소의 위험도 체크 후 발송.

실제 측정소 데이터가 없을 때는 risk_logic의 더미 데이터를 사용합니다.
Supabase 연동 시 _fetch_station_risks() 를 실제 DB 조회로 교체하세요.
"""

import os
from dotenv import load_dotenv

from user_store    import get_active_users, haversine_km, log_alert, already_alerted_today
from alert_sender  import send_sms, build_alert_text
from risk_logic    import compute_risk

load_dotenv()

ALERT_RADIUS_KM  = float(os.getenv("ALERT_RADIUS_KM", "30"))   # 반경 km
ALERT_MIN_LEVEL  = os.getenv("ALERT_MIN_LEVEL", "yellow")       # yellow 이상 알림

# ── 측정소 목록 (실 운영 시 Supabase에서 가져옴) ──────────────────────────────
_STATIONS = [
    {"id": "HAN_EST_01", "name": "한강 하구 1번",  "lat": 37.67, "lng": 126.57},
    {"id": "HAN_EST_02", "name": "한강 하구 2번",  "lat": 37.62, "lng": 126.61},
    {"id": "HAN_EST_03", "name": "한강 하구 3번",  "lat": 37.58, "lng": 126.65},
    {"id": "ICN_CST_01", "name": "인천 연안 1번",  "lat": 37.50, "lng": 126.55},
    {"id": "ICN_CST_02", "name": "인천 연안 2번",  "lat": 37.43, "lng": 126.62},
    {"id": "ICN_CST_03", "name": "인천 연안 3번",  "lat": 37.36, "lng": 126.58},
    {"id": "ICN_CST_04", "name": "인천 연안 4번",  "lat": 37.29, "lng": 126.54},
    {"id": "WST_SEA_01", "name": "서해 1번",       "lat": 37.00, "lng": 126.30},
    {"id": "WST_SEA_02", "name": "서해 2번",       "lat": 36.50, "lng": 126.20},
    {"id": "WST_SEA_03", "name": "서해 3번",       "lat": 36.10, "lng": 126.48},
    {"id": "GEU_RIV_01", "name": "금강 1번",       "lat": 36.25, "lng": 127.00},
    {"id": "GEU_RIV_02", "name": "금강 2번",       "lat": 36.10, "lng": 126.92},
    {"id": "NAK_RIV_01", "name": "낙동강 1번",     "lat": 35.85, "lng": 128.65},
    {"id": "NAK_RIV_02", "name": "낙동강 2번",     "lat": 35.50, "lng": 128.55},
    {"id": "STH_SEA_01", "name": "남해 1번",       "lat": 34.90, "lng": 128.20},
    {"id": "STH_SEA_02", "name": "남해 2번",       "lat": 34.75, "lng": 127.80},
]


def _fetch_station_risks() -> dict:
    """
    측정소별 최신 위험도를 반환.
    실 운영: Supabase risk_status 테이블 조회.
    지금: risk_logic으로 더미 계산.
    """
    import random
    risks = {}
    for s in _STATIONS:
        random.seed(s["id"] + str(__import__("datetime").date.today()))
        level, reason = compute_risk(
            water_temp  = random.uniform(22.0, 29.0),
            ph          = random.uniform(7.5, 9.8),
            total_p     = random.uniform(0.02, 0.10),
            dissolved_o2= random.uniform(2.5, 8.0),
        )
        risks[s["id"]] = {"level": level, "reason": reason, "station": s}
    return risks


def _should_alert(level: str) -> bool:
    order = {"green": 0, "yellow": 1, "red": 2}
    threshold = order.get(ALERT_MIN_LEVEL, 1)
    return order.get(level, 0) >= threshold


def run_sms_alerts():
    print("[sms_alerts] 알림 체크 시작")
    users  = get_active_users()
    risks  = _fetch_station_risks()

    if not users:
        print("[sms_alerts] 등록된 사용자 없음")
        return

    sent = 0
    for user in users:
        ulat, ulng = user["lat"], user["lng"]

        # 반경 내 측정소 중 위험도 가장 높은 곳
        candidates = []
        for sid, rdata in risks.items():
            st   = rdata["station"]
            dist = haversine_km(ulat, ulng, st["lat"], st["lng"])
            if dist <= ALERT_RADIUS_KM:
                candidates.append((dist, sid, rdata))

        if not candidates:
            continue

        candidates.sort(key=lambda x: (
            {"red": 0, "yellow": 1, "green": 2}.get(x[2]["level"], 9), x[0]))

        dist, sid, rdata = candidates[0]
        level  = rdata["level"]
        reason = rdata["reason"]
        name   = rdata["station"]["name"]

        if not _should_alert(level):
            continue

        if already_alerted_today(user["kakao_id"], sid):
            continue

        text = build_alert_text(level, name, reason, dist)
        ok   = send_sms(user["phone"], text)

        if ok:
            log_alert(user["kakao_id"], sid, level, text)
            print(f"[sms_alerts] 발송 ✓ → {user['phone']} | {name} | {level}")
            sent += 1
        else:
            print(f"[sms_alerts] 발송 실패 → {user['phone']}")

    print(f"[sms_alerts] 완료 — {sent}/{len(users)}명 발송")
