class Task {
  String name;
  bool isCompleted;
  String priority;
  List<Subtask> subtasks; // New field for subtasks

  Task({
    required this.name,
    this.isCompleted = false,
    required this.priority,
    this.subtasks = const [], // Default to empty list if no subtasks are passed
  });

  // Method to add a subtask to the task
  void addSubtask(Subtask subtask) {
    subtasks.add(subtask);
  }

  // Method to mark the task as completed
  void toggleCompletion() {
    isCompleted = !isCompleted;
  }
}

class Subtask {
  String name;
  String dueTime;

  Subtask({required this.name, required this.dueTime});
}
