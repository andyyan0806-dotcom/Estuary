import 'package:flutter/material.dart';
import '../models/measurement.dart';
import '../models/risk_status.dart';


class RiskExplanationScreen extends StatelessWidget {
  final String stationName;
  final Measurement? measurement;
  final RiskStatus risk;

  const RiskExplanationScreen({
    super.key,
    required this.stationName,
    required this.measurement,
    required this.risk,
  });

  @override
  Widget build(BuildContext context) {
    final level = risk.level;
    return Scaffold(
      appBar: AppBar(title: Text('$stationName · 판단 근거')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Overall verdict
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: level.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: level.color, width: 1.5),
              ),
              child: Row(
                children: [
                  Icon(level.icon, color: level.color, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('위험 등급: ${level.label}',
                            style: TextStyle(
                                color: level.color,
                                fontWeight: FontWeight.bold,
                                fontSize: 16)),
                        const SizedBox(height: 4),
                        const Text('판단 알고리즘: BIO 임계값 기반 규칙',
                            style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text('지표별 임계값 비교',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 12),
            _ThresholdRow(
              label: '수온',
              current: measurement?.waterTemp,
              threshold: 25.0,
              unit: '°C',
              aboveDanger: true,
            ),
            _ThresholdRow(
              label: '총인 (T-P)',
              current: measurement?.totalP,
              threshold: 0.05,
              unit: 'mg/L',
              aboveDanger: true,
            ),
            _ThresholdRow(
              label: '용존산소 (DO)',
              current: measurement?.dissolvedO2,
              threshold: 4.0,
              unit: 'mg/L',
              aboveDanger: false,
            ),
            _ThresholdRow(
              label: 'pH',
              current: measurement?.ph,
              threshold: 9.0,
              unit: '',
              aboveDanger: true,
            ),
            const SizedBox(height: 20),
            // Red logic explainer
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('판단 규칙',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 6),
                  Text('• 위험(🔴): 수온 ≥ 25°C AND 총인 ≥ 0.05 mg/L',
                      style: TextStyle(fontSize: 13)),
                  Text('• 주의(🟡): 위 조건 중 1가지 이상 충족',
                      style: TextStyle(fontSize: 13)),
                  Text('• 정상(🟢): 조건 없음',
                      style: TextStyle(fontSize: 13)),
                  SizedBox(height: 6),
                  Text(
                    '주의: 이 예보는 공공 데이터 기반 예측값입니다. '
                    '실제 의사결정 전 관계 기관의 공식 발표를 확인하세요.',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThresholdRow extends StatelessWidget {
  final String label;
  final double? current;
  final double threshold;
  final String unit;
  final bool aboveDanger;

  const _ThresholdRow({
    required this.label,
    required this.current,
    required this.threshold,
    required this.unit,
    required this.aboveDanger,
  });

  bool get _triggered {
    if (current == null) return false;
    return aboveDanger ? current! >= threshold : current! <= threshold;
  }

  @override
  Widget build(BuildContext context) {
    final triggered = _triggered;
    final barValue = current == null
        ? 0.0
        : aboveDanger
            ? (current! / (threshold * 2)).clamp(0.0, 1.0)
            : (1 - (current! / (threshold * 2))).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: triggered ? Colors.red.shade50 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: triggered ? Colors.red.shade200 : Colors.grey.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              Row(
                children: [
                  if (triggered)
                    const Icon(Icons.warning_amber,
                        color: Colors.orange, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    current != null
                        ? '${current!.toStringAsFixed(3)} $unit'
                        : '측정값 없음',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: triggered ? Colors.red : Colors.black87,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: barValue,
              backgroundColor: Colors.grey.shade200,
              color: triggered ? Colors.red : Colors.green,
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '임계값: ${aboveDanger ? "≥" : "≤"} $threshold $unit',
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
