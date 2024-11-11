import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:task_management_cw06/task_list_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: TaskListScreen(),
    );
  }
}
