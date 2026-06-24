import 'risk_status.dart';

class Alert {
  final String id;
  final String userId;
  final String? locationId;
  final String? stationId;
  final RiskLevel level;
  final DateTime sentAt;

  const Alert({
    required this.id,
    required this.userId,
    this.locationId,
    this.stationId,
    required this.level,
    required this.sentAt,
  });

  factory Alert.fromJson(Map<String, dynamic> j) => Alert(
        id: j['id'] as String,
        userId: j['user_id'] as String,
        locationId: j['location_id'] as String?,
        stationId: j['station_id'] as String?,
        level: riskLevelFromString(j['level'] as String),
        sentAt: DateTime.parse(j['sent_at'] as String),
      );
}
