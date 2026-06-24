import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

const _cities = [
  _City('서울', 37.5665, 126.9780, 14, true),
  _City('부산', 35.1796, 129.0756, 12, true),
  _City('인천', 37.4563, 126.7052, 11, true),
  _City('대구', 35.8714, 128.6014, 11, true),
  _City('대전', 36.3504, 127.3845, 11, true),
  _City('광주', 35.1595, 126.8526, 11, true),
  _City('울산', 35.5384, 129.3114, 10, false),
  _City('수원', 37.2636, 127.0286, 10, false),
  _City('청주', 36.6424, 127.4890, 10, false),
  _City('전주', 35.8242, 127.1480, 10, false),
  _City('창원', 35.2280, 128.6811, 10, false),
  _City('포항', 36.0190, 129.3435, 10, false),
  _City('강릉', 37.7519, 128.8761, 10, false),
  _City('춘천', 37.8747, 127.7342, 10, false),
  _City('여수', 34.7604, 127.6622, 10, false),
  _City('군산', 35.9678, 126.7368, 9,  false),
  _City('목포', 34.8118, 126.3922, 10, false),
  _City('속초', 38.2070, 128.5919, 9,  false),
  _City('제주', 33.4996, 126.5312, 10, false),
  _City('안동', 36.5650, 128.7290, 9,  false),
];

class _City {
  final String name;
  final double lat, lng, size;
  final bool major;
  const _City(this.name, this.lat, this.lng, this.size, this.major);
}

class CityLabelsLayer extends StatelessWidget {
  const CityLabelsLayer({super.key});

  @override
  Widget build(BuildContext context) {
    return MarkerLayer(
      markers: _cities.map((c) => Marker(
        point: LatLng(c.lat, c.lng),
        width: 72,
        height: 22,
        child: Center(
          child: Text(
            c.name,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: c.size,
              fontWeight: c.major ? FontWeight.w700 : FontWeight.w500,
              color: c.major
                  ? const Color(0xFFCFE2F3)
                  : const Color(0xFF8AB0CC),
              letterSpacing: c.major ? 1.0 : 0.4,
              shadows: const [
                Shadow(color: Color(0xFF0A1628), blurRadius: 4),
                Shadow(color: Color(0xFF0A1628), blurRadius: 8),
              ],
            ),
          ),
        ),
      )).toList(),
    );
  }
}
