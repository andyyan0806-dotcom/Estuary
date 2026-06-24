import 'package:flutter/material.dart';

enum RiskLevel { green, yellow, red }

extension RiskLevelExt on RiskLevel {
  Color get color {
    switch (this) {
      case RiskLevel.green:
        return const Color(0xFF4CAF50);
      case RiskLevel.yellow:
        return const Color(0xFFFFC107);
      case RiskLevel.red:
        return const Color(0xFFF44336);
    }
  }

  String get label {
    switch (this) {
      case RiskLevel.green:
        return '정상';
      case RiskLevel.yellow:
        return '주의';
      case RiskLevel.red:
        return '위험';
    }
  }

  IconData get icon {
    switch (this) {
      case RiskLevel.green:
        return Icons.check_circle;
      case RiskLevel.yellow:
        return Icons.warning_amber;
      case RiskLevel.red:
        return Icons.dangerous;
    }
  }
}

RiskLevel riskLevelFromString(String s) {
  switch (s) {
    case 'red':
      return RiskLevel.red;
    case 'yellow':
      return RiskLevel.yellow;
    default:
      return RiskLevel.green;
  }
}

class RiskStatus {
  final String id;
  final String stationId;
  final DateTime ts;
  final RiskLevel level;
  final String reason;

  const RiskStatus({
    required this.id,
    required this.stationId,
    required this.ts,
    required this.level,
    required this.reason,
  });

  factory RiskStatus.fromJson(Map<String, dynamic> j) => RiskStatus(
        id: j['id'] as String,
        stationId: j['station_id'] as String,
        ts: DateTime.parse(j['ts'] as String),
        level: riskLevelFromString(j['level'] as String),
        reason: j['reason'] as String? ?? '',
      );
}
