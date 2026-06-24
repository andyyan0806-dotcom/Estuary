import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/risk_status.dart';
import '../providers/location_provider.dart';
import '../providers/station_provider.dart';

class RegisteredPointsScreen extends StatefulWidget {
  const RegisteredPointsScreen({super.key});

  @override
  State<RegisteredPointsScreen> createState() =>
      _RegisteredPointsScreenState();
}

class _RegisteredPointsScreenState extends State<RegisteredPointsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LocationProvider>().refresh();
    });
  }

  void _showAddDialog() {
    final labelCtrl = TextEditingController();
    final latCtrl = TextEditingController();
    final lngCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('관심 지점 추가'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: labelCtrl,
              decoration: const InputDecoration(labelText: '이름 (예: 내 양식장)'),
            ),
            TextField(
              controller: latCtrl,
              decoration: const InputDecoration(labelText: '위도 (예: 37.41)'),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
            TextField(
              controller: lngCtrl,
              decoration: const InputDecoration(labelText: '경도 (예: 126.73)'),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('취소')),
          ElevatedButton(
            onPressed: () async {
              final label = labelCtrl.text.trim();
              final lat = double.tryParse(latCtrl.text.trim());
              final lng = double.tryParse(lngCtrl.text.trim());
              if (label.isEmpty || lat == null || lng == null) return;
              Navigator.pop(ctx);
              await context.read<LocationProvider>().add(label, lat, lng);
            },
            child: const Text('저장'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final locProvider = context.watch<LocationProvider>();
    final stProvider = context.watch<StationProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('관심 지점'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: locProvider.refresh,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        child: const Icon(Icons.add_location_alt),
      ),
      body: locProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : locProvider.locations.isEmpty
              ? const Center(
                  child: Text(
                    '등록된 지점이 없습니다.\n+ 버튼으로 추가하세요.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: locProvider.locations.length,
                  separatorBuilder: (context, i) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final loc = locProvider.locations[i];
                    // Find nearest station risk
                    RiskLevel nearestLevel = RiskLevel.green;
                    double minDist = double.infinity;
                    for (final s in stProvider.stations) {
                      final d = _dist(loc.lat, loc.lng, s.lat, s.lng);
                      if (d < minDist) {
                        minDist = d;
                        nearestLevel = stProvider.riskFor(s.id);
                      }
                    }

                    return Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(
                            color: nearestLevel.color.withValues(alpha: 0.5)),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              nearestLevel.color.withValues(alpha: 0.2),
                          child: Icon(nearestLevel.icon,
                              color: nearestLevel.color),
                        ),
                        title: Text(loc.label),
                        subtitle: Text(
                          '${loc.lat.toStringAsFixed(4)}, ${loc.lng.toStringAsFixed(4)}  ·  ${nearestLevel.label}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.grey),
                          onPressed: () =>
                              context.read<LocationProvider>().remove(loc.id),
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  double _dist(double lat1, double lng1, double lat2, double lng2) {
    // Simple Euclidean approx for sorting only
    final dlat = lat1 - lat2;
    final dlng = lng1 - lng2;
    return dlat * dlat + dlng * dlng;
  }
}
