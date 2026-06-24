import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/station.dart';
import '../models/measurement.dart';
import '../models/risk_status.dart';
import '../models/user_location.dart';
import '../models/alert.dart';

class SupabaseService {
  static final _client = Supabase.instance.client;

  // ── Stations ──────────────────────────────────────────────────────────────

  static Future<List<Station>> getStations() async {
    final data = await _client.from('stations').select();
    return (data as List).map((j) => Station.fromJson(j)).toList();
  }

  // ── Measurements ──────────────────────────────────────────────────────────

  static Future<Measurement?> getLatestMeasurement(String stationId) async {
    final data = await _client
        .from('measurements')
        .select()
        .eq('station_id', stationId)
        .order('ts', ascending: false)
        .limit(1);
    if ((data as List).isEmpty) return null;
    return Measurement.fromJson(data.first);
  }

  static Future<List<Measurement>> getMeasurementHistory(
    String stationId, {
    int limit = 48,
  }) async {
    final data = await _client
        .from('measurements')
        .select()
        .eq('station_id', stationId)
        .order('ts', ascending: false)
        .limit(limit);
    return (data as List).map((j) => Measurement.fromJson(j)).toList();
  }

  // ── Risk status ───────────────────────────────────────────────────────────

  static Future<RiskStatus?> getLatestRisk(String stationId) async {
    final data = await _client
        .from('risk_status')
        .select()
        .eq('station_id', stationId)
        .order('ts', ascending: false)
        .limit(1);
    if ((data as List).isEmpty) return null;
    return RiskStatus.fromJson(data.first);
  }

  static Future<Map<String, RiskStatus>> getAllLatestRisks() async {
    final stations = await getStations();
    final Map<String, RiskStatus> result = {};
    await Future.wait(stations.map((s) async {
      final r = await getLatestRisk(s.id);
      if (r != null) result[s.id] = r;
    }));
    return result;
  }

  // ── User locations ────────────────────────────────────────────────────────

  static Future<List<UserLocation>> getUserLocations() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];
    final data = await _client
        .from('user_locations')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return (data as List).map((j) => UserLocation.fromJson(j)).toList();
  }

  static Future<void> addUserLocation(
      String label, double lat, double lng) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    await _client.from('user_locations').insert({
      'user_id': userId,
      'label': label,
      'lat': lat,
      'lng': lng,
    });
  }

  static Future<void> deleteUserLocation(String id) async {
    await _client.from('user_locations').delete().eq('id', id);
  }

  // ── Alerts ────────────────────────────────────────────────────────────────

  static Future<List<Alert>> getAlertHistory({int limit = 50}) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];
    final data = await _client
        .from('alerts')
        .select()
        .eq('user_id', userId)
        .order('sent_at', ascending: false)
        .limit(limit);
    return (data as List).map((j) => Alert.fromJson(j)).toList();
  }

  // ── FCM token ─────────────────────────────────────────────────────────────

  static Future<void> upsertFcmToken(String token) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    await _client.from('fcm_tokens').upsert({
      'user_id': userId,
      'token': token,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }
}
