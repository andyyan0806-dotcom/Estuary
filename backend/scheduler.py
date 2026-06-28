"""
스케줄러: 데이터 수집 + 카카오 SMS 알림 발송.

실행:
  python scheduler.py          # 백그라운드 루프
  python scheduler.py --once   # 즉시 한 번 실행 후 종료 (테스트용)
"""

import sys
import time
import schedule

from collector  import run_collection
from sms_alerts import run_sms_alerts


def run_all():
    run_collection()
    run_sms_alerts()


schedule.every(1).hours.do(run_collection)
schedule.every(30).minutes.do(run_sms_alerts)


if __name__ == "__main__":
    if "--once" in sys.argv:
        print("[scheduler] 1회 실행 모드")
        run_all()
        sys.exit(0)

    print("[scheduler] 시작 — 데이터 수집 1h마다, 알림 체크 30분마다")
    run_all()   # 시작 즉시 1회 실행
    while True:
        schedule.run_pending()
        time.sleep(30)
