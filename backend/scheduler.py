"""
Scheduler: runs collector every hour, push sender every 30 minutes.
Start with:  python scheduler.py
"""

import schedule
import time
from collector import run_collection
from push_sender import run_push

schedule.every(1).hours.do(run_collection)
schedule.every(30).minutes.do(run_push)

if __name__ == "__main__":
    print("[scheduler] Starting — collection every 1h, push check every 30m")
    run_collection()  # run immediately on start
    run_push()
    while True:
        schedule.run_pending()
        time.sleep(30)
