"""
카카오 i 오픈빌더 웹훅 서버 (Flask).

카카오 오픈빌더 설정:
  1. center.kakao.com → 채널 생성 (무료, 개인 계정 OK)
  2. i.kakao.com/openbuilder → 봇 생성 → 스킬 URL = 이 서버의 /kakao/webhook
  3. 블록 4개 생성 (아래 INTENT 참고):
     - 시작하기 / 등록
     - 위치입력 (사용자발화: "위치는 {address}")
     - 전화번호입력 (사용자발화: "{phone}")
     - 상태확인

대화 흐름:
  사용자: "등록" → 봇: "양식장 주소를 알려주세요"
  사용자: "인천시 남동구 논현동" → 봇: "전화번호를 입력해주세요"
  사용자: "010-1234-5678" → 봇: "등록 완료 ✅"
  사용자: "상태확인" → 봇: "현재 가장 가까운 측정소 상태 [...]"
  사용자: "알림끄기" → 봇: "알림 비활성화"
"""

import os
import re

from flask import Flask, request, jsonify
from dotenv import load_dotenv

from user_store import (
    upsert_user, get_active_users, deactivate_user,
    set_reg_state, get_reg_state, clear_reg_state,
    haversine_km,
)
from risk_logic import compute_risk

load_dotenv()

app = Flask(__name__)

# ── 더미 측정소 (실제 운영 시 DB / API에서 가져옴) ──────────────────────────
_STATIONS = [
    {"id": "HAN_EST_01", "name": "한강 하구 1번", "lat": 37.67, "lng": 126.57},
    {"id": "HAN_EST_02", "name": "한강 하구 2번", "lat": 37.62, "lng": 126.61},
    {"id": "ICN_CST_01", "name": "인천 연안 1번", "lat": 37.50, "lng": 126.55},
    {"id": "ICN_CST_02", "name": "인천 연안 2번", "lat": 37.43, "lng": 126.62},
    {"id": "ICN_CST_03", "name": "인천 연안 3번", "lat": 37.36, "lng": 126.58},
    {"id": "WST_SEA_01", "name": "서해 1번",      "lat": 37.00, "lng": 126.30},
    {"id": "WST_SEA_02", "name": "서해 2번",      "lat": 36.50, "lng": 126.20},
]


def _nearest_risk(lat: float, lng: float):
    """가장 가까운 측정소 + 더미 위험도 반환."""
    closest = min(_STATIONS, key=lambda s: haversine_km(lat, lng, s["lat"], s["lng"]))
    dist = haversine_km(lat, lng, closest["lat"], closest["lng"])
    # 실제 운영 시 DB에서 최신 측정값 조회
    import random; random.seed(closest["id"])
    level, reason = compute_risk(
        water_temp=random.uniform(22, 28),
        ph=random.uniform(7.5, 9.5),
        total_p=random.uniform(0.02, 0.08),
        dissolved_o2=random.uniform(3.5, 7.0),
    )
    return closest, dist, level, reason


# ── 응답 빌더 ──────────────────────────────────────────────────────────────────

def _simple(text: str, quick_replies: list | None = None) -> dict:
    resp = {
        "version": "2.0",
        "template": {
            "outputs": [{"simpleText": {"text": text}}],
        },
    }
    if quick_replies:
        resp["template"]["quickReplies"] = quick_replies
    return resp


def _quick(label: str, msg: str | None = None) -> dict:
    return {"label": label, "action": "message", "messageText": msg or label}


# ── 주요 핸들러 ────────────────────────────────────────────────────────────────

def handle_start(kakao_id: str) -> dict:
    set_reg_state(kakao_id, "awaiting_location")
    return _simple(
        "안녕하세요! 🌊 녹조 알림 서비스입니다.\n\n"
        "양식장 주소(또는 동/읍 이름)를 입력해 주세요.\n"
        "예) 인천시 남동구 논현동",
        quick_replies=[_quick("취소", "취소")],
    )


def handle_location_input(kakao_id: str, utterance: str,
                           kakao_location: dict | None) -> dict:
    """
    오픈빌더에서 '위치 공유' 버튼 → kakao_location 에 lat/lng 포함.
    텍스트 주소 입력 → utterance 에서 파싱 (카카오 지도 API 없이 주소만 저장).
    """
    if kakao_location:
        lat = float(kakao_location.get("lat") or kakao_location.get("latitude", 0))
        lng = float(kakao_location.get("lng") or kakao_location.get("longitude", 0))
        address = kakao_location.get("address", "위치 공유")
    else:
        # 텍스트 주소만 저장 (좌표 변환은 추후 Kakao 주소 API 연동)
        lat, lng = 37.41, 126.72   # 인천 기본값 (실 운영 시 지오코딩 필요)
        address = utterance.strip()

    set_reg_state(kakao_id, "awaiting_phone", lat=lat, lng=lng, address=address)
    return _simple(
        f"📍 위치 확인: {address}\n\n"
        "알림 받을 전화번호를 입력해 주세요.\n"
        "예) 010-1234-5678",
    )


def handle_phone_input(kakao_id: str, utterance: str) -> dict:
    phone = re.sub(r"[^0-9]", "", utterance)
    if not re.fullmatch(r"010\d{8}", phone):
        return _simple("📵 전화번호 형식이 올바르지 않습니다.\n010-XXXX-XXXX 형식으로 다시 입력해 주세요.")

    state = get_reg_state(kakao_id)
    if not state or state["step"] != "awaiting_phone":
        return _simple("처음부터 다시 시작해 주세요.", quick_replies=[_quick("등록")])

    upsert_user(kakao_id, phone, state["lat"], state["lng"], state["address"])
    clear_reg_state(kakao_id)

    return _simple(
        f"✅ 등록 완료!\n\n"
        f"📍 위치: {state['address']}\n"
        f"📱 전화번호: {phone[:3]}-{phone[3:7]}-{phone[7:]}\n\n"
        f"위험 수준 상승 시 즉시 문자로 알려드릴게요.",
        quick_replies=[_quick("상태확인"), _quick("알림끄기")],
    )


def handle_status(kakao_id: str) -> dict:
    users = [u for u in get_active_users() if u["kakao_id"] == kakao_id]
    if not users:
        return _simple(
            "등록된 양식장이 없습니다.",
            quick_replies=[_quick("등록")],
        )
    u = users[0]
    station, dist, level, reason = _nearest_risk(u["lat"], u["lng"])
    emoji = {"red": "🔴", "yellow": "🟡", "green": "🟢"}.get(level, "⚪")
    label = {"red": "위험", "yellow": "주의", "green": "정상"}.get(level, "-")
    return _simple(
        f"{emoji} 현재 상태: {label}\n\n"
        f"📍 내 위치: {u['address']}\n"
        f"📡 인근 측정소: {station['name']} ({dist:.1f}km)\n"
        f"⚠️ {reason}",
        quick_replies=[_quick("등록 수정", "등록"), _quick("알림끄기")],
    )


def handle_deactivate(kakao_id: str) -> dict:
    deactivate_user(kakao_id)
    return _simple(
        "알림이 비활성화됐습니다.\n다시 받으시려면 '등록'을 눌러주세요.",
        quick_replies=[_quick("등록")],
    )


# ── Webhook 엔드포인트 ─────────────────────────────────────────────────────────

@app.route("/kakao/webhook", methods=["POST"])
def webhook():
    body       = request.get_json(force=True)
    utterance  = body.get("userRequest", {}).get("utterance", "").strip()
    kakao_id   = body.get("userRequest", {}).get("user", {}).get("id", "unknown")

    # 카카오 위치 공유 블록이 보내는 extra data
    extra      = body.get("action", {}).get("params", {})
    kakao_loc  = extra.get("location")   # {"lat": ..., "lng": ..., "address": ...}

    # 현재 등록 진행 상태 확인
    state = get_reg_state(kakao_id)

    # 명령어 우선 처리
    if utterance in ("등록", "시작", "시작하기", "재등록"):
        return jsonify(handle_start(kakao_id))

    if utterance in ("상태확인", "현재상태", "확인"):
        return jsonify(handle_status(kakao_id))

    if utterance in ("알림끄기", "취소", "구독취소"):
        return jsonify(handle_deactivate(kakao_id))

    # 진행 중인 등록 플로우
    if state:
        if state["step"] == "awaiting_location":
            return jsonify(handle_location_input(kakao_id, utterance, kakao_loc))
        if state["step"] == "awaiting_phone":
            return jsonify(handle_phone_input(kakao_id, utterance))

    # 기본 응답
    return jsonify(_simple(
        "안녕하세요! 녹조 알림 서비스입니다. 🌊\n\n"
        "아래 버튼을 눌러 시작하세요.",
        quick_replies=[_quick("등록"), _quick("상태확인")],
    ))


@app.route("/health")
def health():
    return "ok"


if __name__ == "__main__":
    port = int(os.getenv("PORT", 5001))
    app.run(host="0.0.0.0", port=port, debug=False)
