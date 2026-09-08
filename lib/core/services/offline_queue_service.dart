import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

final offlineQueueServiceProvider = Provider<OfflineQueueService>((ref) {
  return OfflineQueueService();
});

class QueuedTask {
  final String id;
  final String type;
  final Map<String, dynamic> payload;
  final DateTime createdAt;

  QueuedTask({
    required this.id,
    required this.type,
    required this.payload,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'payload': payload,
        'createdAt': createdAt.toIso8601String(),
      };

  factory QueuedTask.fromJson(Map<String, dynamic> json) => QueuedTask(
        id: json['id'],
        type: json['type'],
        payload: json['payload'] as Map<String, dynamic>,
        createdAt: DateTime.parse(json['createdAt']),
      );
}

class OfflineQueueService {
  static const String _queueKey = 'offline_tasks_queue';
  final _uuid = const Uuid();

  Future<void> enqueueTask(String type, Map<String, dynamic> payload) async {
    final prefs = await SharedPreferences.getInstance();
    final tasks = await getTasks();
    
    final newTask = QueuedTask(
      id: _uuid.v4(),
      type: type,
      payload: payload,
      createdAt: DateTime.now(),
    );
    
    tasks.add(newTask);
    await _saveTasks(prefs, tasks);
  }

  Future<List<QueuedTask>> getTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final tasksString = prefs.getStringList(_queueKey) ?? [];
    return tasksString
        .map((t) => QueuedTask.fromJson(jsonDecode(t)))
        .toList();
  }

  Future<void> removeTask(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final tasks = await getTasks();
    tasks.removeWhere((t) => t.id == id);
    await _saveTasks(prefs, tasks);
  }

  Future<void> _saveTasks(SharedPreferences prefs, List<QueuedTask> tasks) async {
    final stringList = tasks.map((t) => jsonEncode(t.toJson())).toList();
    await prefs.setStringList(_queueKey, stringList);
  }
}
