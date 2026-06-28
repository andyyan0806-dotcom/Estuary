-- 카카오 등록 사용자
CREATE TABLE IF NOT EXISTS kakao_users (
  kakao_id   TEXT PRIMARY KEY,
  phone      TEXT NOT NULL,
  lat        DOUBLE PRECISION NOT NULL,
  lng        DOUBLE PRECISION NOT NULL,
  address    TEXT,
  active     BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 등록 진행 상태 (멀티스텝 챗봇용)
CREATE TABLE IF NOT EXISTS reg_state (
  kakao_id TEXT PRIMARY KEY,
  step     TEXT NOT NULL,
  lat      DOUBLE PRECISION,
  lng      DOUBLE PRECISION,
  address  TEXT,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 알림 발송 로그 (중복 방지)
CREATE TABLE IF NOT EXISTS alert_log (
  id         BIGSERIAL PRIMARY KEY,
  kakao_id   TEXT NOT NULL,
  station_id TEXT NOT NULL,
  level      TEXT NOT NULL,
  message    TEXT,
  sent_at    TIMESTAMPTZ DEFAULT NOW()
);

-- 측정소 테이블
CREATE TABLE IF NOT EXISTS stations (
  id     TEXT PRIMARY KEY,
  name   TEXT NOT NULL,
  lat    DOUBLE PRECISION NOT NULL,
  lng    DOUBLE PRECISION NOT NULL,
  region TEXT
);

-- 기본 측정소 시드
INSERT INTO stations VALUES
  ('HAN_EST_01','한강 하구 1번',37.67,126.57,'han_estuary'),
  ('HAN_EST_02','한강 하구 2번',37.62,126.61,'han_estuary'),
  ('HAN_EST_03','한강 하구 3번',37.58,126.65,'han_estuary'),
  ('ICN_CST_01','인천 연안 1번',37.50,126.55,'incheon_coast'),
  ('ICN_CST_02','인천 연안 2번',37.43,126.62,'incheon_coast'),
  ('ICN_CST_03','인천 연안 3번',37.36,126.58,'incheon_coast'),
  ('ICN_CST_04','인천 연안 4번',37.29,126.54,'incheon_coast'),
  ('WST_SEA_01','서해 1번',37.00,126.30,'west_sea'),
  ('WST_SEA_02','서해 2번',36.50,126.20,'west_sea'),
  ('NAK_RIV_01','낙동강 1번',35.85,128.65,'nakdong_river'),
  ('STH_SEA_01','남해 1번',34.90,128.20,'south_sea')
ON CONFLICT DO NOTHING;
