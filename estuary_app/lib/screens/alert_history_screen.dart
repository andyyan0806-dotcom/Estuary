import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/risk_status.dart';
import '../providers/location_provider.dart';

class AlertHistoryScreen extends StatefulWidget {
  const AlertHistoryScreen({super.key});

  @override
  State<AlertHistoryScreen> createState() => _AlertHistoryScreenState();
}

class _AlertHistoryScreenState extends State<AlertHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LocationProvider>().refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LocationProvider>();
    final alerts = provider.alerts;

    return Scaffold(
      appBar: AppBar(
        title: const Text('알림 기록'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: provider.refresh,
          ),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : alerts.isEmpty
              ? const Center(
                  child: Text(
                    '전송된 알림이 없습니다.',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: alerts.length,
                  separatorBuilder: (context, i) =>
                      const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final alert = alerts[i];
                    final level = alert.level;
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: level.color.withValues(alpha: 0.15),
                        child: Icon(level.icon, color: level.color),
                      ),
                      title: Text(
                        '[${level.label}] 수질 경보',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: level.color,
                        ),
                      ),
                      subtitle: Text(
                        alert.stationId ?? '알 수 없는 지점',
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: Text(
                        DateFormat('MM/dd HH:mm')
                            .format(alert.sentAt.toLocal()),
                        style: const TextStyle(
                            fontSize: 11, color: Colors.grey),
                      ),
                    );
                  },
                ),
    );
  }
}
