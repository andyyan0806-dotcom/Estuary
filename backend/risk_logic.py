"""
BIO threshold logic for eutrophication risk assessment.
Red   = water_temp >= 25°C AND total_p >= 0.05 mg/L
Yellow = any single primary condition met
Green  = no conditions met
"""

THRESHOLDS = {
    "water_temp": 25.0,   # °C
    "total_p":    0.05,   # mg/L
    "dissolved_o2": 4.0,  # mg/L  (below this = danger)
    "ph":         9.0,    # above this = excess photosynthesis
}


def compute_risk(water_temp, ph, total_p, dissolved_o2):
    """
    Returns (level, reason) where level is 'green' | 'yellow' | 'red'.
    Any None input is treated as missing (not triggering a condition).
    """
    conditions = []
    reasons = []

    if water_temp is not None and water_temp >= THRESHOLDS["water_temp"]:
        conditions.append("temp")
        reasons.append(f"수온 {water_temp:.1f}°C ≥ {THRESHOLDS['water_temp']}°C")

    if total_p is not None and total_p >= THRESHOLDS["total_p"]:
        conditions.append("phosphorus")
        reasons.append(f"총인 {total_p:.3f} mg/L ≥ {THRESHOLDS['total_p']} mg/L")

    if dissolved_o2 is not None and dissolved_o2 <= THRESHOLDS["dissolved_o2"]:
        conditions.append("do_low")
        reasons.append(f"용존산소 {dissolved_o2:.1f} mg/L ≤ {THRESHOLDS['dissolved_o2']} mg/L")

    if ph is not None and ph >= THRESHOLDS["ph"]:
        conditions.append("ph_high")
        reasons.append(f"pH {ph:.1f} ≥ {THRESHOLDS['ph']}")

    if "temp" in conditions and "phosphorus" in conditions:
        level = "red"
    elif len(conditions) >= 1:
        level = "yellow"
    else:
        level = "green"

    reason_text = " | ".join(reasons) if reasons else "모든 지표 정상"
    return level, reason_text
