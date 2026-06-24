class Station {
  final String id;
  final String name;
  final double lat;
  final double lng;
  final String region;

  const Station({
    required this.id,
    required this.name,
    required this.lat,
    required this.lng,
    required this.region,
  });

  factory Station.fromJson(Map<String, dynamic> j) => Station(
        id: j['id'] as String,
        name: j['name'] as String,
        lat: (j['lat'] as num).toDouble(),
        lng: (j['lng'] as num).toDouble(),
        region: j['region'] as String,
      );
}
