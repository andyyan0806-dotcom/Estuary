import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

// South Korea mainland — detailed enough to look clean
const _mainland = [
  LatLng(38.63, 125.08), LatLng(38.48, 125.45), LatLng(38.30, 126.18),
  LatLng(38.05, 126.48), LatLng(37.85, 126.60), LatLng(37.70, 126.52),
  LatLng(37.47, 126.52), LatLng(37.27, 126.44), LatLng(37.08, 126.38),
  LatLng(36.95, 126.35), LatLng(36.72, 126.38), LatLng(36.50, 126.40),
  LatLng(36.30, 126.46), LatLng(36.12, 126.52), LatLng(35.90, 126.50),
  LatLng(35.72, 126.46), LatLng(35.55, 126.46), LatLng(35.35, 126.42),
  LatLng(35.12, 126.40), LatLng(34.92, 126.42), LatLng(34.72, 126.47),
  LatLng(34.55, 126.50), LatLng(34.38, 126.72), LatLng(34.28, 126.92),
  LatLng(34.24, 127.22), LatLng(34.35, 127.52), LatLng(34.55, 127.75),
  LatLng(34.68, 127.90), LatLng(34.80, 128.08), LatLng(34.84, 128.40),
  LatLng(34.85, 128.62), LatLng(35.00, 128.78), LatLng(35.10, 129.00),
  LatLng(35.20, 129.18), LatLng(35.38, 129.32), LatLng(35.50, 129.42),
  LatLng(35.68, 129.48), LatLng(35.90, 129.54), LatLng(36.10, 129.55),
  LatLng(36.30, 129.48), LatLng(36.55, 129.44), LatLng(36.75, 129.38),
  LatLng(36.95, 129.30), LatLng(37.20, 129.23), LatLng(37.50, 129.14),
  LatLng(37.70, 129.02), LatLng(37.90, 128.84), LatLng(38.10, 128.60),
  LatLng(38.28, 128.38), LatLng(38.45, 128.05), LatLng(38.60, 127.48),
  LatLng(38.63, 125.08),
];

const _jeju = [
  LatLng(33.57, 126.15), LatLng(33.28, 126.15), LatLng(33.14, 126.38),
  LatLng(33.12, 126.62), LatLng(33.22, 126.96), LatLng(33.48, 126.98),
  LatLng(33.58, 126.80), LatLng(33.57, 126.15),
];

// Han River (simplified) — gives nice geographic detail
const _hanRiver = [
  LatLng(37.61, 126.78), LatLng(37.57, 126.94), LatLng(37.54, 127.12),
  LatLng(37.52, 127.36), LatLng(37.54, 127.58), LatLng(37.42, 127.74),
];

// Nakdong River (simplified)
const _nakdong = [
  LatLng(36.56, 128.73), LatLng(36.30, 128.55), LatLng(36.00, 128.38),
  LatLng(35.75, 128.22), LatLng(35.55, 128.12), LatLng(35.30, 128.42),
  LatLng(35.10, 128.85), LatLng(35.09, 128.97),
];

class KoreaMapLayer extends StatelessWidget {
  const KoreaMapLayer({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      PolygonLayer(polygons: [
        // Mainland fill
        Polygon(
          points: _mainland,
          color: const Color(0xFF16304F),
          borderColor: const Color(0xFF2E5C8A),
          borderStrokeWidth: 1.8,
        ),
        // Jeju fill
        Polygon(
          points: _jeju,
          color: const Color(0xFF16304F),
          borderColor: const Color(0xFF2E5C8A),
          borderStrokeWidth: 1.2,
        ),
      ]),
      // Rivers
      PolylineLayer(polylines: [
        Polyline(
          points: _hanRiver,
          color: const Color(0xFF1A5080),
          strokeWidth: 2.0,
        ),
        Polyline(
          points: _nakdong,
          color: const Color(0xFF1A5080),
          strokeWidth: 1.8,
        ),
      ]),
    ]);
  }
}
