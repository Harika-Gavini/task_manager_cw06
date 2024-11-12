import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TaskListScreen extends StatefulWidget {
  @override
  _TaskListScreenState createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _taskController = TextEditingController();
  String _selectedPriority = 'Medium';
  String _sortOption = 'Priority';
  String? _filterPriority;
  bool showOnlyCompleted = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Task List'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.of(context).pushReplacementNamed('/login');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _taskController,
                    decoration: InputDecoration(
                      labelText: 'Enter task name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                DropdownButton<String>(
                  value: _selectedPriority,
                  items: ['High', 'Medium', 'Low'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _selectedPriority = newValue!;
                    });
                  },
                ),
                IconButton(
                  icon: Icon(Icons.add),
                  onPressed: addTask,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  DropdownButton<String>(
                    value: _sortOption,
                    items: ['Priority', 'Due Date', 'Completion Status']
                        .map((String option) {
                      return DropdownMenuItem<String>(
                        value: option,
                        child: Text("Sort by $option"),
                      );
                    }).toList(),
                    onChanged: (newSortOption) {
                      setState(() {
                        _sortOption = newSortOption!;
                      });
                    },
                  ),
                  SizedBox(width: 10),
                  DropdownButton<String?>(
                    value: _filterPriority,
                    hint: Text('Filter by Priority'),
                    items: [null, 'High', 'Medium', 'Low'].map((String? value) {
                      return DropdownMenuItem<String?>(
                        value: value,
                        child: Text(value ?? 'All'),
                      );
                    }).toList(),
                    onChanged: (newFilter) {
                      setState(() {
                        _filterPriority = newFilter;
                      });
                    },
                  ),
                  SizedBox(width: 10),
                  Row(
                    children: [
                      Text("Completed Only"),
                      Switch(
                        value: showOnlyCompleted,
                        onChanged: (value) {
                          setState(() {
                            showOnlyCompleted = value;
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<QuerySnapshot>(
              future: _fetchTasks(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text("No tasks available."));
                }
                final tasks = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    var task = tasks[index];
                    return ListTile(
                      title: Text(task['name']),
                      subtitle: Row(
                        children: [
                          Icon(
                            Icons.circle,
                            color: _getPriorityColor(task['priority']),
                            size: 10,
                          ),
                          SizedBox(width: 5),
                          Text('Priority: ${task['priority']}'),
                        ],
                      ),
                      leading: Checkbox(
                        value: task['completed'],
                        activeColor: Colors.green,
                        onChanged: (value) {
                          toggleCompletion(task.id, value);
                        },
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () => deleteTask(task.id),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> addTask() async {
    if (_taskController.text.isNotEmpty) {
      await _firestore.collection('tasks').add({
        'name': _taskController.text,
        'completed': false,
        'priority': _selectedPriority,
        'dueDate': DateTime.now(),
      });
      _taskController.clear();
      setState(() {}); // Refresh to show new task
    }
  }

  Future<void> toggleCompletion(String taskId, bool? isCompleted) async {
    await _firestore.collection('tasks').doc(taskId).update({
      'completed': isCompleted,
    });
    setState(() {});
  }

  Future<void> deleteTask(String taskId) async {
    await _firestore.collection('tasks').doc(taskId).delete();
    setState(() {});
  }

  Future<QuerySnapshot> _fetchTasks() async {
    Query query = _firestore.collection('tasks');

    if (_filterPriority != null) {
      query = query.where('priority', isEqualTo: _filterPriority);
    }

    if (showOnlyCompleted) {
      query = query.where('completed', isEqualTo: true);
    }

    switch (_sortOption) {
      case 'Priority':
        query = query.orderBy('priority', descending: false);
        break;
      case 'Due Date':
        query = query.orderBy('dueDate');
        break;
      case 'Completion Status':
        query = query.orderBy('completed', descending: true);
        break;
    }

    return query.get();
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'High':
        return Colors.red;
      case 'Medium':
        return Colors.yellow;
      case 'Low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
