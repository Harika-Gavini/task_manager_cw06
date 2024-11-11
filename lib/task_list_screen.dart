import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:task_management_cw06/model/task.dart';

class TaskListScreen extends StatefulWidget {
  @override
  _TaskListScreenState createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  TextEditingController _taskController = TextEditingController();
  String _priority = 'Low';
  DateTime _dueDate = DateTime.now();
  late FirebaseAuth _auth;
  late User _user;

  @override
  void initState() {
    super.initState();
    _auth = FirebaseAuth.instance;
    _user = _auth.currentUser!;
  }

  // Add a task
  Future<void> _addTask() async {
    final task = Task(
      id: DateTime.now().toString(),
      name: _taskController.text,
      priority: _priority,
      dueDate: _dueDate,
    );

    await FirebaseFirestore.instance.collection('tasks').add(task.toMap());

    // Clear the input field
    _taskController.clear();
  }

  // Toggle task completion status
  Future<void> _toggleTaskCompletion(String taskId, bool isCompleted) async {
    await FirebaseFirestore.instance.collection('tasks').doc(taskId).update({
      'isCompleted': !isCompleted,
    });
  }

  // Delete a task
  Future<void> _deleteTask(String taskId) async {
    await FirebaseFirestore.instance.collection('tasks').doc(taskId).delete();
  }

  // Task widget
  Widget _buildTaskItem(Task task) {
    return ListTile(
      title: Text(
        task.name,
        style: TextStyle(
          decoration: task.isCompleted
              ? TextDecoration.lineThrough
              : TextDecoration.none,
        ),
      ),
      leading: Checkbox(
        value: task.isCompleted,
        onChanged: (_) => _toggleTaskCompletion(task.id, task.isCompleted),
      ),
      trailing: IconButton(
        icon: Icon(Icons.delete),
        onPressed: () => _deleteTask(task.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Task Management')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _taskController,
              decoration: InputDecoration(labelText: 'Enter Task'),
            ),
            DropdownButton<String>(
              value: _priority,
              onChanged: (newPriority) {
                setState(() {
                  _priority = newPriority!;
                });
              },
              items: ['Low', 'Medium', 'High'].map((priority) {
                return DropdownMenuItem<String>(
                  value: priority,
                  child: Text(priority),
                );
              }).toList(),
            ),
            ElevatedButton(
              onPressed: _addTask,
              child: Text('Add Task'),
            ),
            Expanded(
              child: StreamBuilder(
                stream: FirebaseFirestore.instance
                    .collection('tasks')
                    .where('userId', isEqualTo: _user.uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(child: CircularProgressIndicator());
                  }

                  final tasks = snapshot.data!.docs
                      .map((doc) => Task.fromMap(doc.id, doc.data()))
                      .toList();

                  return ListView.builder(
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      return _buildTaskItem(tasks[index]);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
