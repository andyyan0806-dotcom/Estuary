import 'package:flutter/foundation.dart';
import '../models/alert.dart';
import '../models/risk_status.dart';
import '../models/user_location.dart';
import '../services/supabase_service.dart';
import 'station_provider.dart' show kDemoMode;

class LocationProvider extends ChangeNotifier {
  List<UserLocation> locations = [];
  List<Alert> alerts = [];
  bool isLoading = false;

  // Demo mock alerts
  static final _demoAlerts = [
    Alert(
      id: 'a1',
      userId: 'demo',
      stationId: 'ICN_CST_01',
      level: RiskLevel.red,
      sentAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    Alert(
      id: 'a2',
      userId: 'demo',
      stationId: 'HAN_EST_01',
      level: RiskLevel.yellow,
      sentAt: DateTime.now().subtract(const Duration(hours: 5)),
    ),
  ];

  Future<void> refresh() async {
    isLoading = true;
    notifyListeners();

    if (kDemoMode) {
      await Future.delayed(const Duration(milliseconds: 400));
      alerts = _demoAlerts;
      isLoading = false;
      notifyListeners();
      return;
    }

    try {
      final results = await Future.wait<Object>([
        SupabaseService.getUserLocations(),
        SupabaseService.getAlertHistory(),
      ]);
      locations = results[0] as List<UserLocation>;
      alerts = results[1] as List<Alert>;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> add(String label, double lat, double lng) async {
    if (kDemoMode) {
      locations = [
        UserLocation(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          userId: 'demo',
          label: label,
          lat: lat,
          lng: lng,
          createdAt: DateTime.now(),
        ),
        ...locations,
      ];
      notifyListeners();
      return;
    }
    await SupabaseService.addUserLocation(label, lat, lng);
    await refresh();
  }

  Future<void> remove(String id) async {
    locations.removeWhere((l) => l.id == id);
    notifyListeners();
    if (!kDemoMode) await SupabaseService.deleteUserLocation(id);
  }
}
