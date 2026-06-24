import 'package:flutter/foundation.dart';
import '../models/station.dart';
import '../models/risk_status.dart';
import '../services/mock_data.dart';
import '../services/supabase_service.dart';

// Set to false once Supabase is configured
const bool kDemoMode = true;

class StationProvider extends ChangeNotifier {
  List<Station> stations = [];
  Map<String, RiskStatus> riskMap = {};
  DateTime? lastUpdated;
  bool isLoading = false;
  String? error;

  Future<void> refresh() async {
    isLoading = true;
    error = null;
    notifyListeners();

    if (kDemoMode) {
      await Future.delayed(const Duration(milliseconds: 600));
      stations = mockStations;
      riskMap = mockRiskMap;
      lastUpdated = DateTime.now();
      isLoading = false;
      notifyListeners();
      return;
    }

    try {
      final results = await Future.wait<Object>([
        SupabaseService.getStations(),
        SupabaseService.getAllLatestRisks(),
      ]);
      stations = results[0] as List<Station>;
      riskMap = results[1] as Map<String, RiskStatus>;
      lastUpdated = DateTime.now();
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  RiskLevel riskFor(String stationId) =>
      riskMap[stationId]?.level ?? RiskLevel.green;
}
