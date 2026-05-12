import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

import '../main.dart';
import '../models/routineModel.dart';
import '../models/taskModel.dart';
import '../models/transactionModel.dart';
import '../service/native_alarm_service.dart';
import '../theme/app_theme.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  bool? canScheduleExactAlarms;
  final TextEditingController importController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadExactAlarmStatus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 100),
          children: [
            _statusCard(),
            const SizedBox(height: 16),
            _section(
              title: 'Notifications',
              children: [
                _actionTile(
                  icon: Icons.notifications_active_outlined,
                  title: 'Test Notification',
                  subtitle: 'Send one notification now.',
                  onTap: _showTestNotification,
                ),
                _actionTile(
                  icon: Icons.alarm_on_outlined,
                  title: 'Refresh Exact Alarm Status',
                  subtitle: _exactAlarmText(),
                  onTap: _loadExactAlarmStatus,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _section(
              title: 'Backup',
              children: [
                _actionTile(
                  icon: Icons.copy_all_outlined,
                  title: 'Copy Backup JSON',
                  subtitle: 'Copy all app data to clipboard.',
                  onTap: _copyBackupJson,
                ),
                _actionTile(
                  icon: Icons.restore_outlined,
                  title: 'Import Backup JSON',
                  subtitle: 'Paste a backup and restore data.',
                  onTap: _showImportSheet,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _section(
              title: 'Phone Setup',
              children: const [
                _InfoTile(
                  icon: Icons.battery_saver_outlined,
                  title: 'Redmi / MIUI',
                  subtitle:
                      'Keep Battery Saver set to No restrictions, allow Autostart, notifications, and exact alarms.',
                ),
              ],
            ),
            const SizedBox(height: 16),
            _section(
              title: 'Danger Zone',
              children: [
                _actionTile(
                  icon: Icons.delete_forever_outlined,
                  title: 'Reset All Data',
                  subtitle: 'Delete tasks, routines, checklist, money, and history.',
                  color: AppTheme.rose,
                  onTap: _confirmResetAll,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: premiumCard(color: AppTheme.ink),
      child: Row(
        children: [
          const Icon(Icons.tune, color: Colors.white),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'App Controls',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _exactAlarmText(),
                  style: const TextStyle(color: Color(0xFFD1D5DB)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _section({required String title, required List<Widget> children}) {
    return Container(
      decoration: premiumCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color color = AppTheme.primary,
  }) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.10),
        child: Icon(icon, color: color),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  Future<void> _loadExactAlarmStatus() async {
    final androidPlugin = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    final status = await androidPlugin?.canScheduleExactNotifications();
    if (!mounted) return;
    setState(() => canScheduleExactAlarms = status);
  }

  String _exactAlarmText() {
    if (canScheduleExactAlarms == null) return 'Exact alarm status unknown.';
    return canScheduleExactAlarms!
        ? 'Exact alarms are allowed.'
        : 'Exact alarms are not allowed.';
  }

  Future<void> _showTestNotification() async {
    await flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      'Tracker Test',
      'Notifications are working.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'routine_channel',
          'Routine Alerts',
          channelDescription: 'Routine reminders',
          icon: 'app_icon',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
    );
    Get.snackbar('Sent', 'Test notification requested.');
  }

  Future<void> _copyBackupJson() async {
    final backup = {
      'version': 1,
      'createdAt': DateTime.now().toIso8601String(),
      'tasks': Hive.box<TaskModel>('tasks').values.map((task) {
        return {
          'title': task.title,
          'isDone': task.isDone,
          'priority': task.priority,
        };
      }).toList(),
      'routines': Hive.box<RoutineModel>('routines').values.map((routine) {
        return {
          'id': routine.id,
          'title': routine.title,
          'hour': routine.hour,
          'minute': routine.minute,
          'isDoneToday': routine.isDoneToday,
          'streak': routine.streak,
          'lastCompletedDate': routine.lastCompletedDate?.toIso8601String(),
          'priority': routine.priority,
        };
      }).toList(),
      'transactions': Hive.box<TransactionModel>('transactions').values.map((tx) {
        return {
          'type': tx.type,
          'amount': tx.amount,
          'date': tx.date.toIso8601String(),
          'note': tx.note,
        };
      }).toList(),
      'checklist': Hive.box('checklist').values.map((raw) {
        return Map<String, dynamic>.from(raw as Map);
      }).toList(),
      'routineHistory': Hive.box('routine_history').values.map((raw) {
        return Map<String, dynamic>.from(raw as Map);
      }).toList(),
      'appMeta': Map<String, dynamic>.from(Hive.box('app_meta').toMap()),
    };

    const encoder = JsonEncoder.withIndent('  ');
    await Clipboard.setData(ClipboardData(text: encoder.convert(backup)));
    Get.snackbar('Copied', 'Backup JSON copied to clipboard.');
  }

  void _showImportSheet() {
    importController.clear();
    Get.bottomSheet(
      SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: importController,
                minLines: 5,
                maxLines: 8,
                decoration: const InputDecoration(
                  hintText: 'Paste backup JSON',
                  prefixIcon: Icon(Icons.restore),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _importBackupJson,
                  child: const Text('Import Backup'),
                ),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  Future<void> _importBackupJson() async {
    try {
      final decoded = jsonDecode(importController.text.trim()) as Map<String, dynamic>;
      await _restoreBackup(decoded);
      Get.back();
      Get.snackbar('Imported', 'Backup restored. Reopen the app to refresh every page.');
    } catch (_) {
      Get.snackbar('Import failed', 'The backup JSON is not valid.');
    }
  }

  Future<void> _restoreBackup(Map<String, dynamic> backup) async {
    final tasksBox = Hive.box<TaskModel>('tasks');
    final routinesBox = Hive.box<RoutineModel>('routines');
    final transactionsBox = Hive.box<TransactionModel>('transactions');
    final checklistBox = Hive.box('checklist');
    final historyBox = Hive.box('routine_history');
    final metaBox = Hive.box('app_meta');

    await _cancelRoutineAlarms();
    await tasksBox.clear();
    await routinesBox.clear();
    await transactionsBox.clear();
    await checklistBox.clear();
    await historyBox.clear();
    await metaBox.clear();

    for (final raw in backup['tasks'] as List? ?? []) {
      final item = Map<String, dynamic>.from(raw as Map);
      await tasksBox.add(TaskModel(
        title: item['title'] as String? ?? '',
        isDone: item['isDone'] as bool? ?? false,
        priority: item['priority'] as String? ?? 'medium',
      ));
    }

    for (final raw in backup['routines'] as List? ?? []) {
      final item = Map<String, dynamic>.from(raw as Map);
      await routinesBox.add(RoutineModel(
        id: item['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
        title: item['title'] as String? ?? '',
        hour: item['hour'] as int? ?? 8,
        minute: item['minute'] as int? ?? 0,
        isDoneToday: item['isDoneToday'] as bool? ?? false,
        streak: item['streak'] as int? ?? 0,
        lastCompletedDate: item['lastCompletedDate'] == null
            ? null
            : DateTime.tryParse(item['lastCompletedDate'] as String),
        priority: item['priority'] as int? ?? 2,
      ));
    }

    for (final raw in backup['transactions'] as List? ?? []) {
      final item = Map<String, dynamic>.from(raw as Map);
      await transactionsBox.add(TransactionModel(
        type: item['type'] as String? ?? 'expense',
        amount: (item['amount'] as num?)?.toDouble() ?? 0,
        date: DateTime.tryParse(item['date'] as String? ?? '') ?? DateTime.now(),
        note: item['note'] as String? ?? '',
      ));
    }

    for (final raw in backup['checklist'] as List? ?? []) {
      await checklistBox.add(Map<String, dynamic>.from(raw as Map));
    }

    for (final raw in backup['routineHistory'] as List? ?? []) {
      await historyBox.add(Map<String, dynamic>.from(raw as Map));
    }

    final appMeta = backup['appMeta'];
    if (appMeta is Map) {
      for (final entry in appMeta.entries) {
        await metaBox.put(entry.key, entry.value);
      }
    }
  }

  Future<void> _confirmResetAll() async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Reset All Data'),
        content: const Text('This deletes all tracker data on this phone.'),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _cancelRoutineAlarms();
      await Hive.box<TaskModel>('tasks').clear();
      await Hive.box<RoutineModel>('routines').clear();
      await Hive.box<TransactionModel>('transactions').clear();
      await Hive.box('checklist').clear();
      await Hive.box('routine_history').clear();
      await Hive.box('app_meta').clear();
      Get.snackbar('Reset complete', 'Reopen the app to refresh every page.');
    }
  }

  Future<void> _cancelRoutineAlarms() async {
    for (final routine in Hive.box<RoutineModel>('routines').values) {
      await flutterLocalNotificationsPlugin.cancel(routine.key);
      await NativeAlarmService.cancelRoutineAlarm(routine.key);
    }
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppTheme.amber.withValues(alpha: 0.10),
        child: Icon(icon, color: AppTheme.amber),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: Text(subtitle),
    );
  }
}
