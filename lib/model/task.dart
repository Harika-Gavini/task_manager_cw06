import 'package:cloud_firestore/cloud_firestore.dart';

class Task {
  String id;
  String name;
  bool isCompleted;
  String priority;
  DateTime dueDate;

  Task({
    required this.id,
    required this.name,
    this.isCompleted = false,
    required this.priority,
    required this.dueDate,
  });

  // Convert a Task object into a map (for Firebase storage)
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'isCompleted': isCompleted,
      'priority': priority,
      'dueDate': dueDate,
    };
  }

  // Create a Task object from a map (from Firebase data)
  factory Task.fromMap(String id, Map<String, dynamic> map) {
    return Task(
      id: id,
      name: map['name'],
      isCompleted: map['isCompleted'],
      priority: map['priority'],
      dueDate: (map['dueDate'] as Timestamp).toDate(),
    );
  }
}
