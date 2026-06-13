import 'package:cloud_firestore/cloud_firestore.dart';

class JournalEntry {
  final String id;
  final String userId;
  final String content;
  final DateTime date;
  final bool isSealed;

  JournalEntry({
    required this.id,
    required this.userId,
    required this.content,
    required this.date,
    this.isSealed = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'content': content,
      'date': Timestamp.fromDate(date),
      'isSealed': isSealed,
    };
  }

  factory JournalEntry.fromMap(Map<String, dynamic> map, String id) {
    return JournalEntry(
      id: id,
      userId: map['userId'] ?? '',
      content: map['content'] ?? '',
      date: (map['date'] as Timestamp).toDate(),
      isSealed: map['isSealed'] ?? true,
    );
  }
}
