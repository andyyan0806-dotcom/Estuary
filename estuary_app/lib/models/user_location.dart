class UserLocation {
  final String id;
  final String userId;
  final String label;
  final double lat;
  final double lng;
  final DateTime createdAt;

  const UserLocation({
    required this.id,
    required this.userId,
    required this.label,
    required this.lat,
    required this.lng,
    required this.createdAt,
  });

  factory UserLocation.fromJson(Map<String, dynamic> j) => UserLocation(
        id: j['id'] as String,
        userId: j['user_id'] as String,
        label: j['label'] as String,
        lat: (j['lat'] as num).toDouble(),
        lng: (j['lng'] as num).toDouble(),
        createdAt: DateTime.parse(j['created_at'] as String),
      );
}
