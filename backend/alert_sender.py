"""
Message sender — SMS via Solapi (무료 계정으로 테스트 가능).
카카오 알림톡은 사업자 등록 후 동일 API로 전환 가능.

환경변수:
  SOLAPI_API_KEY     — Solapi 콘솔에서 발급
  SOLAPI_API_SECRET  — Solapi 콘솔에서 발급
  SOLAPI_SENDER      — 발신번호 (사전 등록 필요, 예: 01012345678)
"""

import os
import hmac
import hashlib
import uuid
from datetime import datetime, timezone

import requests
from dotenv import load_dotenv

load_dotenv()

SOLAPI_API_KEY    = os.getenv("SOLAPI_API_KEY", "")
SOLAPI_API_SECRET = os.getenv("SOLAPI_API_SECRET", "")
SOLAPI_SENDER     = os.getenv("SOLAPI_SENDER", "")

_BASE = "https://api.solapi.com"


def _auth_header() -> dict:
    """HMAC-SHA256 인증 헤더 생성."""
    date    = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    salt    = uuid.uuid4().hex
    data    = date + salt
    sig     = hmac.new(
        SOLAPI_API_SECRET.encode(),
        data.encode(),
        hashlib.sha256,
    ).hexdigest()
    return {
        "Authorization": f'HMAC-SHA256 apiKey={SOLAPI_API_KEY}, date={date}, salt={salt}, signature={sig}',
        "Content-Type": "application/json",
    }


def send_sms(to: str, text: str) -> bool:
    """
    SMS 발송. 성공 시 True.
    to 형식: '01012345678' (하이픈 없이)
    """
    if not all([SOLAPI_API_KEY, SOLAPI_API_SECRET, SOLAPI_SENDER]):
        print(f"[alert_sender] 환경변수 미설정 — 콘솔 출력만:\n  TO={to}\n  MSG={text}")
        return True   # 개발 모드: 전송 실패로 처리하지 않음

    payload = {
        "message": {
            "to":   to.replace("-", ""),
            "from": SOLAPI_SENDER.replace("-", ""),
            "text": text,
            "type": "SMS",
        }
    }
    try:
        r = requests.post(
            f"{_BASE}/messages/v4/send",
            json=payload,
            headers=_auth_header(),
            timeout=10,
        )
        r.raise_for_status()
        return True
    except Exception as e:
        print(f"[alert_sender] SMS 발송 실패: {e}")
        return False


def build_alert_text(level: str, station_name: str, reason: str,
                     distance_km: float) -> str:
    emoji = {"red": "🔴", "yellow": "🟡"}.get(level, "🟢")
    label = {"red": "위험", "yellow": "주의"}.get(level, "정상")
    return (
        f"{emoji} [녹조 {label} 알림]\n"
        f"인근 측정소: {station_name} ({distance_km:.1f}km)\n"
        f"원인: {reason}\n"
        f"양식장 관리에 주의해 주세요.\n"
        f"— 부영양화 예보 서비스"
    )
