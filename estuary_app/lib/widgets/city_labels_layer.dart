import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

// Tier 1 — 특별시/광역시  (always visible)
// Tier 2 — 도청소재지 + 주요 시  (zoom ≥ 7.8)
// Tier 3 — 나머지 시  (zoom ≥ 9.2)

const _cities = [
  // ── Tier 1: 특별시/광역시 ─────────────────────────────────
  _City('서울',   37.5665, 126.9780, 14.0, 1),
  _City('부산',   35.1796, 129.0756, 13.0, 1),
  _City('인천',   37.4563, 126.7052, 12.5, 1),
  _City('대구',   35.8714, 128.6014, 12.5, 1),
  _City('대전',   36.3504, 127.3845, 12.5, 1),
  _City('광주',   35.1595, 126.8526, 12.5, 1),
  _City('울산',   35.5384, 129.3114, 12.0, 1),
  _City('세종',   36.4800, 127.2890, 11.5, 1),

  // ── Tier 2: 주요 시 ───────────────────────────────────────
  // 경기
  _City('수원',   37.2636, 127.0286, 11.0, 2),
  _City('고양',   37.6584, 126.8320, 11.0, 2),
  _City('용인',   37.2411, 127.1775, 11.0, 2),
  _City('성남',   37.4449, 127.1388, 10.5, 2),
  _City('화성',   37.1994, 126.8320, 10.5, 2),
  _City('안산',   37.3219, 126.8309, 10.5, 2),
  _City('안양',   37.3943, 126.9568, 10.5, 2),
  _City('남양주', 37.6360, 127.2164, 10.5, 2),
  _City('부천',   37.5034, 126.7660, 10.5, 2),
  _City('평택',   36.9921, 127.1128, 10.5, 2),
  _City('파주',   37.7600, 126.7800, 10.5, 2),
  _City('의정부', 37.7382, 127.0338, 10.0, 2),
  // 강원
  _City('춘천',   37.8747, 127.7342, 11.0, 2),
  _City('원주',   37.3422, 127.9202, 10.5, 2),
  _City('강릉',   37.7519, 128.8761, 10.5, 2),
  _City('속초',   38.2070, 128.5919, 10.0, 2),
  // 충북
  _City('청주',   36.6424, 127.4890, 11.0, 2),
  _City('충주',   36.9910, 127.9259, 10.5, 2),
  // 충남
  _City('천안',   36.8151, 127.1139, 11.0, 2),
  _City('아산',   36.7898, 127.0020, 10.0, 2),
  _City('서산',   36.7847, 126.4503, 10.0, 2),
  // 전북
  _City('전주',   35.8242, 127.1480, 11.0, 2),
  _City('군산',   35.9678, 126.7368, 10.5, 2),
  _City('익산',   35.9483, 126.9578, 10.0, 2),
  // 전남
  _City('목포',   34.8118, 126.3922, 10.5, 2),
  _City('여수',   34.7604, 127.6622, 10.5, 2),
  _City('순천',   34.9503, 127.4874, 10.5, 2),
  // 경북
  _City('포항',   36.0190, 129.3435, 11.0, 2),
  _City('구미',   36.1193, 128.3444, 10.5, 2),
  _City('안동',   36.5650, 128.7290, 10.5, 2),
  _City('경주',   35.8560, 129.2248, 10.5, 2),
  // 경남
  _City('창원',   35.2280, 128.6811, 11.0, 2),
  _City('진주',   35.1800, 128.1076, 10.5, 2),
  _City('김해',   35.2285, 128.8890, 10.5, 2),
  _City('양산',   35.3351, 129.0366, 10.0, 2),
  // 제주
  _City('제주',   33.4996, 126.5312, 11.0, 2),
  _City('서귀포', 33.2541, 126.5600, 10.0, 2),

  // ── Tier 3: 나머지 시 ─────────────────────────────────────
  _City('광명',   37.4785, 126.8647,  9.5, 3),
  _City('오산',   37.1500, 127.0773,  9.5, 3),
  _City('시흥',   37.3800, 126.8030,  9.5, 3),
  _City('군포',   37.3617, 126.9352,  9.5, 3),
  _City('하남',   37.5390, 127.2148,  9.5, 3),
  _City('구리',   37.5943, 127.1296,  9.5, 3),
  _City('이천',   37.2720, 127.4350,  9.5, 3),
  _City('안성',   37.0100, 127.2799,  9.5, 3),
  _City('김포',   37.6150, 126.7159,  9.5, 3),
  _City('광주시', 37.4295, 127.2553,  9.5, 3), // 경기도 광주
  _City('양주',   37.7850, 127.0460,  9.5, 3),
  _City('포천',   37.8956, 127.2004,  9.5, 3),
  _City('여주',   37.2983, 127.6374,  9.5, 3),
  _City('동두천', 37.9036, 127.0607,  9.5, 3),
  _City('과천',   37.4295, 126.9878,  9.5, 3),
  _City('동해',   37.5244, 129.1143,  9.5, 3),
  _City('태백',   37.1645, 128.9853,  9.5, 3),
  _City('삼척',   37.4500, 129.1651,  9.5, 3),
  _City('제천',   37.1326, 128.1909,  9.5, 3),
  _City('공주',   36.4465, 127.1190,  9.5, 3),
  _City('보령',   36.3334, 126.6128,  9.5, 3),
  _City('논산',   36.1870, 127.0990,  9.5, 3),
  _City('계룡',   36.2740, 127.2490,  9.5, 3),
  _City('당진',   36.8900, 126.6280,  9.5, 3),
  _City('정읍',   35.5699, 126.8557,  9.5, 3),
  _City('남원',   35.4162, 127.3904,  9.5, 3),
  _City('김제',   35.8032, 126.8808,  9.5, 3),
  _City('나주',   35.0160, 126.7106,  9.5, 3),
  _City('광양',   34.9406, 127.6960,  9.5, 3),
  _City('김천',   36.1396, 128.1136,  9.5, 3),
  _City('영주',   36.8059, 128.6243,  9.5, 3),
  _City('영천',   35.9734, 128.9375,  9.5, 3),
  _City('상주',   36.4109, 128.1592,  9.5, 3),
  _City('문경',   36.5869, 128.1862,  9.5, 3),
  _City('경산',   35.8254, 128.7416,  9.5, 3),
  _City('통영',   34.8542, 128.4336,  9.5, 3),
  _City('사천',   35.0030, 128.0647,  9.5, 3),
  _City('밀양',   35.4979, 128.7461,  9.5, 3),
  _City('거제',   34.8797, 128.6247,  9.5, 3),
];

class _City {
  final String name;
  final double lat, lng, size;
  final int tier;
  const _City(this.name, this.lat, this.lng, this.size, this.tier);
}

class CityLabelsLayer extends StatelessWidget {
  const CityLabelsLayer({super.key});

  @override
  Widget build(BuildContext context) {
    // maybeOf returns null if camera not ready yet — default to low zoom so
    // only tier-1 cities render on the first frame.
    final zoom = MapCamera.maybeOf(context)?.zoom ?? 6.0;

    final visible = _cities.where((c) {
      if (c.tier == 1) return true;
      if (c.tier == 2) return zoom >= 7.8;
      return zoom >= 9.2;
    }).toList();

    return MarkerLayer(
      markers: visible.map((c) {
        final isMajor = c.tier == 1;
        final isMid   = c.tier == 2;
        // Korean chars are ~full-width; give plenty of room so text isn't clipped
        final w = (c.name.length * c.size * 1.15 + 16).clamp(48.0, 120.0);
        final h = c.size + 12.0;
        return Marker(
          point: LatLng(c.lat, c.lng),
          width: w,
          height: h,
          child: Center(
            child: Text(
              c.name,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: c.size,
                fontWeight: isMajor
                    ? FontWeight.w800
                    : isMid
                        ? FontWeight.w600
                        : FontWeight.w500,
                color: isMajor
                    ? const Color(0xFFE8F1FA)
                    : isMid
                        ? const Color(0xFFADCAE0)
                        : const Color(0xFF7A9EB8),
                letterSpacing: isMajor ? 1.0 : 0.2,
                shadows: const [
                  Shadow(color: Color(0xFF010810), blurRadius: 5),
                  Shadow(color: Color(0xFF010810), blurRadius: 10),
                  Shadow(color: Color(0xFF010810), blurRadius: 3),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
