import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/health_log_service.dart';
import '../models/health_log.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _logService = HealthLogService();
  List<DailyLog> _logs = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final logs = await _logService.getAllDailyLogs();
    setState(() => _logs = logs);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('歷史紀錄')),
      body: _logs.isEmpty
          ? const Center(child: Text('目前還沒有紀錄'))
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: _logs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final log = _logs[i];
                final hasWarning = log.abnormalTestCount > 0;
                return Card(
                  color: hasWarning ? Colors.red.shade50 : null,
                  child: ListTile(
                    leading: Icon(
                      hasWarning ? Icons.warning_amber : Icons.check_circle,
                      color: hasWarning ? Colors.red : Colors.green,
                    ),
                    title: Text(DateFormat('yyyy/MM/dd').format(log.date)),
                    subtitle: Text(
                      '飲水 ${log.waterIntakeMl}ml・工作 ${log.totalWorkMinutes}分鐘・'
                      '休息 ${log.restCount}次・異常自測 ${log.abnormalTestCount}次',
                    ),
                  ),
                );
              },
            ),
    );
  }
}
