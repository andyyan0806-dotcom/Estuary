import 'package:flutter/material.dart';

class InfoScreen extends StatelessWidget {
  const InfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('데이터 출처 및 정보')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Section(
              title: '앱 소개',
              content:
                  '이 앱은 서울 생활하수에서 비롯된 질소·인 오염이 한강 하구를 거쳐 '
                  '인천 해안에 부영양화(적조/녹조)를 유발하는 과정을 실시간으로 추적하고, '
                  '인천 양식 어업인과 시민에게 사전 경보를 제공합니다.',
            ),
            const SizedBox(height: 12),
            _Section(
              title: '데이터 출처',
              content: '• 환경부 수질측정망 실시간 수질정보\n'
                  '  (국립환경과학원 · 공공데이터포털 data.go.kr)\n\n'
                  '• 수집 주기: 매 1시간\n'
                  '• 측정 항목: 수온, pH, 총인(T-P), 용존산소(DO)',
            ),
            const SizedBox(height: 12),
            _Section(
              title: '위험 판단 알고리즘',
              content: '부영양화 임계값 기반 규칙 (BIO Logic):\n\n'
                  '🔴 위험: 수온 ≥ 25°C AND 총인 ≥ 0.05 mg/L\n'
                  '🟡 주의: 위 조건 중 1가지 충족\n'
                  '         또는 DO ≤ 4 mg/L 또는 pH ≥ 9.0\n'
                  '🟢 정상: 해당 없음\n\n'
                  '임계값은 초기 설정값으로, 실제 데이터 수집 후 보정됩니다.',
            ),
            const SizedBox(height: 12),
            _Section(
              title: '면책 조항',
              content: '이 앱의 예보는 공공 데이터 기반 참고 정보로, '
                  '공식 기관의 발표를 대체하지 않습니다.\n'
                  '실제 피해 예방을 위한 최종 의사결정 시에는 반드시 '
                  '인천 해양수산국 또는 국립환경과학원의 공식 발표를 확인하시기 바랍니다.',
            ),
            const SizedBox(height: 12),
            _Section(
              title: '버전',
              content: 'v1.0.0  ·  June 2026\n'
                  '개발: Estuary Project',
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String content;
  const _Section({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 8),
          Text(content, style: const TextStyle(height: 1.5, fontSize: 13)),
        ],
      ),
    );
  }
}
