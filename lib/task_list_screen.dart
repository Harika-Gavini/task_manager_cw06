import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TaskListScreen extends StatefulWidget {
  @override
  _TaskListScreenState createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final _firestore = FirebaseFirestore.instance;
  String _selectedPriority = 'Medium'; // Default Priority
  String _sortOption = 'Priority'; // Default Sort Option
  String? _filterPriority; // The selected filter

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
                  child: Text('Filter Options'),
                ),
                IconButton(
                  icon: Icon(Icons.add),
                  onPressed: _showAddTaskDialog,
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
                  // Sort by dropdown
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
                  // Filter by priority dropdown
                  DropdownButton<String?>(
                    value: _filterPriority,
                    hint: Text('Filter by Priority'),
                    items: ['All', 'High', 'Medium', 'Low'].map((String value) {
                      return DropdownMenuItem<String?>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (newFilter) {
                      setState(() {
                        _filterPriority = newFilter;
                      });
                    },
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
                    return Card(
                      margin: EdgeInsets.all(8),
                      child: ListTile(
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
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.delete),
                              onPressed: () => deleteTask(task.id),
                            ),
                            IconButton(
                              icon: Icon(Icons.add),
                              onPressed: () => _showAddSubtaskDialog(task.id),
                            ),
                          ],
                        ),
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

  // Method to show Add Task Dialog
  Future<void> _showAddTaskDialog() async {
    String taskName = '';
    String taskPriority = 'Medium';
    DateTime dueDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Add Task"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(labelText: 'Task name'),
                onChanged: (value) {
                  taskName = value;
                },
              ),
              SizedBox(height: 10),
              DropdownButton<String>(
                value: taskPriority,
                items: ['High', 'Medium', 'Low'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (newValue) {
                  taskPriority = newValue!;
                },
              ),
              SizedBox(height: 10),
              GestureDetector(
                onTap: () async {
                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: dueDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2101),
                  );
                  if (pickedDate != null && pickedDate != dueDate)
                    setState(() {
                      dueDate = pickedDate;
                    });
                },
                child: Row(
                  children: [
                    Text('Due Date: ${dueDate.toLocal()}'),
                    Icon(Icons.calendar_today),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                if (taskName.isNotEmpty) {
                  await _firestore.collection('tasks').add({
                    'name': taskName,
                    'completed': false,
                    'priority': taskPriority,
                    'dueDate': dueDate,
                  });
                  Navigator.pop(context);
                  setState(() {});
                }
              },
              child: Text("Add"),
            ),
          ],
        );
      },
    );
  }

  // Method to toggle completion status
  Future<void> toggleCompletion(String taskId, bool? isCompleted) async {
    await _firestore.collection('tasks').doc(taskId).update({
      'completed': isCompleted,
    });
    setState(() {});
  }

  // Method to delete a task
  Future<void> deleteTask(String taskId) async {
    await _firestore.collection('tasks').doc(taskId).delete();
    setState(() {});
  }

  // Method to fetch tasks based on filter and sort options
  Future<QuerySnapshot> _fetchTasks() async {
    Query query = _firestore.collection('tasks');

    // Filter by priority
    if (_filterPriority != null && _filterPriority != 'All') {
      query = query.where('priority', isEqualTo: _filterPriority);
    }

    // Sort by selected option
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

  // Method to show Add Subtask Dialog
  Future<void> _showAddSubtaskDialog(String taskId) async {
    String subtaskName = '';
    TimeOfDay selectedTime = TimeOfDay.now();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Add Subtask"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(labelText: 'Subtask name'),
                onChanged: (value) {
                  subtaskName = value;
                },
              ),
              SizedBox(height: 10),
              GestureDetector(
                onTap: () async {
                  TimeOfDay? time = await showTimePicker(
                    context: context,
                    initialTime: selectedTime,
                  );
                  if (time != null) {
                    setState(() {
                      selectedTime = time;
                    });
                  }
                },
                child: Row(
                  children: [
                    Text('Due Time: ${selectedTime.format(context)}'),
                    Icon(Icons.access_time),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                if (subtaskName.isNotEmpty) {
                  await _firestore
                      .collection('tasks')
                      .doc(taskId)
                      .collection('subtasks')
                      .add({
                    'name': subtaskName,
                    'dueTime': selectedTime.format(context),
                  });
                  Navigator.pop(context);
                  setState(() {});
                }
              },
              child: Text("Add"),
            ),
          ],
        );
      },
    );
  }

  // Helper method to get priority color
  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'High':
        return Colors.red;
      case 'Medium':
        return Colors.orange;
      case 'Low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
