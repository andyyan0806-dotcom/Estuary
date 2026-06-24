import '../models/measurement.dart';
import '../models/risk_status.dart';
import '../models/station.dart';

const mockStations = [
  // ── 한강 하구 ──────────────────────────────────────────────────────────
  Station(id: 'HAN_EST_01', name: '한강하구 전류리', lat: 37.6850, lng: 126.5280, region: 'han_estuary'),
  Station(id: 'HAN_EST_02', name: '한강하구 강화대교', lat: 37.7200, lng: 126.5000, region: 'han_estuary'),
  Station(id: 'HAN_EST_03', name: '한강하구 초지대교', lat: 37.6600, lng: 126.5400, region: 'han_estuary'),

  // ── 인천 해안 ──────────────────────────────────────────────────────────
  Station(id: 'ICN_CST_01', name: '인천 소래포구', lat: 37.4110, lng: 126.7330, region: 'incheon_coast'),
  Station(id: 'ICN_CST_02', name: '인천 영종도', lat: 37.4900, lng: 126.4900, region: 'incheon_coast'),
  Station(id: 'ICN_CST_03', name: '인천 강화 동막해변', lat: 37.5900, lng: 126.4200, region: 'incheon_coast'),
  Station(id: 'ICN_CST_04', name: '인천 연안부두', lat: 37.4600, lng: 126.6100, region: 'incheon_coast'),

  // ── 서해 ───────────────────────────────────────────────────────────────
  Station(id: 'WHN_01', name: '군산 금강 하구', lat: 35.9900, lng: 126.7100, region: 'west_sea'),
  Station(id: 'WHN_02', name: '서산 천수만', lat: 36.6400, lng: 126.5100, region: 'west_sea'),
  Station(id: 'WHN_03', name: '새만금 방조제', lat: 35.8200, lng: 126.5500, region: 'west_sea'),
  Station(id: 'WHN_04', name: '태안 안면도', lat: 36.4000, lng: 126.3500, region: 'west_sea'),

  // ── 금강 ───────────────────────────────────────────────────────────────
  Station(id: 'GUM_01', name: '금강 공주보', lat: 36.4500, lng: 127.1200, region: 'geum_river'),
  Station(id: 'GUM_02', name: '금강 부여보', lat: 36.2750, lng: 126.9100, region: 'geum_river'),

  // ── 영산강 ─────────────────────────────────────────────────────────────
  Station(id: 'YSK_01', name: '영산강 나주', lat: 35.0200, lng: 126.7300, region: 'yeongsan_river'),
  Station(id: 'YSK_02', name: '영산강 하구 목포', lat: 34.8100, lng: 126.4500, region: 'yeongsan_river'),

  // ── 남해 ───────────────────────────────────────────────────────────────
  Station(id: 'SOU_01', name: '여수 돌산도', lat: 34.6900, lng: 127.7300, region: 'south_sea'),
  Station(id: 'SOU_02', name: '통영 한산도', lat: 34.7800, lng: 128.4000, region: 'south_sea'),
  Station(id: 'SOU_03', name: '거제 외포', lat: 34.8700, lng: 128.5800, region: 'south_sea'),
  Station(id: 'SOU_04', name: '광양만', lat: 34.9200, lng: 127.7000, region: 'south_sea'),

  // ── 낙동강 / 동남해 ────────────────────────────────────────────────────
  Station(id: 'NAK_01', name: '낙동강 상류 안동', lat: 36.5650, lng: 128.7290, region: 'nakdong_river'),
  Station(id: 'NAK_02', name: '낙동강 구미보', lat: 36.1000, lng: 128.3500, region: 'nakdong_river'),
  Station(id: 'NAK_03', name: '낙동강 합천보', lat: 35.5600, lng: 128.1600, region: 'nakdong_river'),
  Station(id: 'NAK_04', name: '낙동강 하구 을숙도', lat: 35.0900, lng: 128.9700, region: 'nakdong_river'),

  // ── 동해 ───────────────────────────────────────────────────────────────
  Station(id: 'EAS_01', name: '속초 청초호', lat: 38.2100, lng: 128.5900, region: 'east_sea'),
  Station(id: 'EAS_02', name: '강릉 경포호', lat: 37.7900, lng: 128.9000, region: 'east_sea'),
  Station(id: 'EAS_03', name: '울진 왕피천', lat: 36.9900, lng: 129.4100, region: 'east_sea'),
  Station(id: 'EAS_04', name: '포항 형산강', lat: 35.9900, lng: 129.3700, region: 'east_sea'),
  Station(id: 'EAS_05', name: '울산 태화강', lat: 35.5500, lng: 129.3200, region: 'east_sea'),

  // ── 제주 ───────────────────────────────────────────────────────────────
  Station(id: 'JEJ_01', name: '제주 화순항', lat: 33.2400, lng: 126.4600, region: 'jeju'),
  Station(id: 'JEJ_02', name: '제주 성산포', lat: 33.4600, lng: 126.9300, region: 'jeju'),
];

final mockRiskMap = {
  // 한강 하구
  'HAN_EST_01': RiskStatus(id: '1', stationId: 'HAN_EST_01', ts: DateTime.now(), level: RiskLevel.red,    reason: '수온 26.3°C | 총인 0.07 mg/L'),
  'HAN_EST_02': RiskStatus(id: '2', stationId: 'HAN_EST_02', ts: DateTime.now(), level: RiskLevel.yellow, reason: '수온 25.8°C'),
  'HAN_EST_03': RiskStatus(id: '3', stationId: 'HAN_EST_03', ts: DateTime.now(), level: RiskLevel.green,  reason: '모든 지표 정상'),
  // 인천
  'ICN_CST_01': RiskStatus(id: '4', stationId: 'ICN_CST_01', ts: DateTime.now(), level: RiskLevel.red,    reason: '수온 27.1°C | 총인 0.09 mg/L'),
  'ICN_CST_02': RiskStatus(id: '5', stationId: 'ICN_CST_02', ts: DateTime.now(), level: RiskLevel.yellow, reason: 'pH 9.2'),
  'ICN_CST_03': RiskStatus(id: '6', stationId: 'ICN_CST_03', ts: DateTime.now(), level: RiskLevel.green,  reason: '모든 지표 정상'),
  'ICN_CST_04': RiskStatus(id: '7', stationId: 'ICN_CST_04', ts: DateTime.now(), level: RiskLevel.yellow, reason: 'DO 3.8 mg/L'),
  // 서해
  'WHN_01': RiskStatus(id: '8',  stationId: 'WHN_01', ts: DateTime.now(), level: RiskLevel.yellow, reason: '총인 0.06 mg/L'),
  'WHN_02': RiskStatus(id: '9',  stationId: 'WHN_02', ts: DateTime.now(), level: RiskLevel.green,  reason: '모든 지표 정상'),
  'WHN_03': RiskStatus(id: '10', stationId: 'WHN_03', ts: DateTime.now(), level: RiskLevel.yellow, reason: '수온 25.2°C'),
  'WHN_04': RiskStatus(id: '11', stationId: 'WHN_04', ts: DateTime.now(), level: RiskLevel.green,  reason: '모든 지표 정상'),
  // 금강
  'GUM_01': RiskStatus(id: '12', stationId: 'GUM_01', ts: DateTime.now(), level: RiskLevel.red,    reason: '수온 26.8°C | 총인 0.08 mg/L'),
  'GUM_02': RiskStatus(id: '13', stationId: 'GUM_02', ts: DateTime.now(), level: RiskLevel.yellow, reason: '수온 25.4°C'),
  // 영산강
  'YSK_01': RiskStatus(id: '14', stationId: 'YSK_01', ts: DateTime.now(), level: RiskLevel.red,    reason: '수온 27.5°C | 총인 0.11 mg/L'),
  'YSK_02': RiskStatus(id: '15', stationId: 'YSK_02', ts: DateTime.now(), level: RiskLevel.yellow, reason: 'DO 3.6 mg/L'),
  // 남해
  'SOU_01': RiskStatus(id: '16', stationId: 'SOU_01', ts: DateTime.now(), level: RiskLevel.green,  reason: '모든 지표 정상'),
  'SOU_02': RiskStatus(id: '17', stationId: 'SOU_02', ts: DateTime.now(), level: RiskLevel.green,  reason: '모든 지표 정상'),
  'SOU_03': RiskStatus(id: '18', stationId: 'SOU_03', ts: DateTime.now(), level: RiskLevel.yellow, reason: 'pH 9.1'),
  'SOU_04': RiskStatus(id: '19', stationId: 'SOU_04', ts: DateTime.now(), level: RiskLevel.yellow, reason: '총인 0.06 mg/L'),
  // 낙동강
  'NAK_01': RiskStatus(id: '20', stationId: 'NAK_01', ts: DateTime.now(), level: RiskLevel.green,  reason: '모든 지표 정상'),
  'NAK_02': RiskStatus(id: '21', stationId: 'NAK_02', ts: DateTime.now(), level: RiskLevel.yellow, reason: '수온 25.1°C'),
  'NAK_03': RiskStatus(id: '22', stationId: 'NAK_03', ts: DateTime.now(), level: RiskLevel.red,    reason: '수온 28.0°C | 총인 0.12 mg/L'),
  'NAK_04': RiskStatus(id: '23', stationId: 'NAK_04', ts: DateTime.now(), level: RiskLevel.yellow, reason: 'DO 3.9 mg/L'),
  // 동해
  'EAS_01': RiskStatus(id: '24', stationId: 'EAS_01', ts: DateTime.now(), level: RiskLevel.green,  reason: '모든 지표 정상'),
  'EAS_02': RiskStatus(id: '25', stationId: 'EAS_02', ts: DateTime.now(), level: RiskLevel.green,  reason: '모든 지표 정상'),
  'EAS_03': RiskStatus(id: '26', stationId: 'EAS_03', ts: DateTime.now(), level: RiskLevel.green,  reason: '모든 지표 정상'),
  'EAS_04': RiskStatus(id: '27', stationId: 'EAS_04', ts: DateTime.now(), level: RiskLevel.yellow, reason: '수온 25.3°C'),
  'EAS_05': RiskStatus(id: '28', stationId: 'EAS_05', ts: DateTime.now(), level: RiskLevel.yellow, reason: 'DO 3.7 mg/L'),
  // 제주
  'JEJ_01': RiskStatus(id: '29', stationId: 'JEJ_01', ts: DateTime.now(), level: RiskLevel.green,  reason: '모든 지표 정상'),
  'JEJ_02': RiskStatus(id: '30', stationId: 'JEJ_02', ts: DateTime.now(), level: RiskLevel.green,  reason: '모든 지표 정상'),
};

Measurement mockMeasurement(String stationId) {
  final risk = mockRiskMap[stationId];
  final isRed    = risk?.level == RiskLevel.red;
  final isYellow = risk?.level == RiskLevel.yellow;
  return Measurement(
    id: 'mock_$stationId',
    stationId: stationId,
    ts: DateTime.now(),
    waterTemp:   isRed ? 27.2 : isYellow ? 25.4 : 22.8,
    ph:          isRed ? 8.9  : isYellow ? 9.1  : 7.8,
    totalP:      isRed ? 0.09 : isYellow ? 0.04 : 0.02,
    dissolvedO2: isRed ? 4.2  : isYellow ? 3.8  : 6.5,
  );
}

List<Measurement> mockHistory(String stationId) {
  final base = mockMeasurement(stationId).waterTemp ?? 22.0;
  return List.generate(48, (i) {
    final t = base + (i - 24) * 0.12 + (i % 5 == 0 ? 0.6 : 0);
    return Measurement(
      id: 'mock_${stationId}_$i',
      stationId: stationId,
      ts: DateTime.now().subtract(Duration(hours: 48 - i)),
      waterTemp: t,
      ph: 7.8,
      totalP: 0.04,
      dissolvedO2: 6.2,
    );
  });
}
