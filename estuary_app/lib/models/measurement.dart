class Measurement {
  final String id;
  final String stationId;
  final DateTime ts;
  final double? waterTemp;
  final double? ph;
  final double? totalP;
  final double? dissolvedO2;

  const Measurement({
    required this.id,
    required this.stationId,
    required this.ts,
    this.waterTemp,
    this.ph,
    this.totalP,
    this.dissolvedO2,
  });

  factory Measurement.fromJson(Map<String, dynamic> j) => Measurement(
        id: j['id'] as String,
        stationId: j['station_id'] as String,
        ts: DateTime.parse(j['ts'] as String),
        waterTemp: (j['water_temp'] as num?)?.toDouble(),
        ph: (j['ph'] as num?)?.toDouble(),
        totalP: (j['total_p'] as num?)?.toDouble(),
        dissolvedO2: (j['dissolved_o2'] as num?)?.toDouble(),
      );
}
