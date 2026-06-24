import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/material.dart';

// Simplified South Korea mainland coastline (counterclockwise winding for hole)
const _koreaMainland = [
  LatLng(38.62, 125.08),
  LatLng(38.28, 126.18),
  LatLng(37.82, 126.58),
  LatLng(37.45, 126.50),
  LatLng(37.17, 126.40),
  LatLng(36.95, 126.35),
  LatLng(36.50, 126.40),
  LatLng(36.10, 126.52),
  LatLng(35.62, 126.46),
  LatLng(35.24, 126.38),
  LatLng(34.95, 126.42),
  LatLng(34.63, 126.53),
  LatLng(34.36, 126.92),
  LatLng(34.28, 127.32),
  LatLng(34.55, 127.75),
  LatLng(34.76, 128.08),
  LatLng(34.84, 128.60),
  LatLng(35.08, 129.02),
  LatLng(35.30, 129.30),
  LatLng(35.50, 129.42),
  LatLng(35.98, 129.55),
  LatLng(36.42, 129.42),
  LatLng(36.76, 129.38),
  LatLng(37.16, 129.22),
  LatLng(37.50, 129.14),
  LatLng(37.90, 128.84),
  LatLng(38.28, 128.37),
  LatLng(38.62, 127.38),
  LatLng(38.62, 125.08),
];

// Jeju Island
const _jejuIsland = [
  LatLng(33.56, 126.15),
  LatLng(33.18, 126.28),
  LatLng(33.12, 126.55),
  LatLng(33.22, 126.93),
  LatLng(33.56, 126.97),
  LatLng(33.56, 126.15),
];

// World-covering rectangle (outer polygon)
const _worldBox = [
  LatLng(-89, -179),
  LatLng(-89,  179),
  LatLng( 89,  179),
  LatLng( 89, -179),
];

class KoreaMaskLayer extends StatelessWidget {
  const KoreaMaskLayer({super.key});

  @override
  Widget build(BuildContext context) {
    return PolygonLayer(
      polygons: [
        Polygon(
          points: _worldBox,
          holePointsList: const [_koreaMainland, _jejuIsland],
          color: const Color(0xFFCADFF0),
          borderStrokeWidth: 0,
        ),
        // Korea border outline
        Polygon(
          points: _koreaMainland,
          color: null,
          borderColor: const Color(0xFF6B8FA8),
          borderStrokeWidth: 1.2,
        ),
        // Jeju border outline
        Polygon(
          points: _jejuIsland,
          color: null,
          borderColor: const Color(0xFF6B8FA8),
          borderStrokeWidth: 1.0,
        ),
      ],
    );
  }
}
