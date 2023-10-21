import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class Todo {
  final String id;
  final String title;
  final bool completed;
  final DateTime due;

  Todo({
    required this.id,
    required this.title,
    required this.completed,
    required this.due,
  });
}

class TodoListScreen extends StatefulWidget {
  @override
  _TodoListScreenState createState() => _TodoListScreenState();
}

class _TodoListScreenState extends State<TodoListScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? _user = FirebaseAuth.instance.currentUser;
  final TextEditingController _textEditingController = TextEditingController();
  late Stream<List<Todo>> _todoStream;

  @override
  void initState() {
    super.initState();
    _todoStream = _fetchTodos();
    _scheduleTaskDeletion();
  }

  Stream<List<Todo>> _fetchTodos() {
    return _firestore
        .collection('users')
        .doc(_user!.uid)
        .collection('todos')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data();
        return Todo(
          id: doc.id,
          title: data['title'],
          completed: data['completed'],
          due: data['due'] != null ? (data['due'] as Timestamp).toDate() : DateTime.now(),
        );
      }).toList();
    });
  }

  void _scheduleTaskDeletion() {
    // Schedule a task to periodically check for overdue tasks
    const Duration checkInterval = Duration(seconds: 1);
    Timer.periodic(checkInterval, (timer) {
      _deleteOverdueTasks();
    });
  }

  void _deleteOverdueTasks() {
    final DateTime now = DateTime.now();
    _firestore
        .collection('users')
        .doc(_user!.uid)
        .collection('todos')
        .where('due', isLessThan: now)
        .get()
        .then((querySnapshot) {
      querySnapshot.docs.forEach((doc) {
        doc.reference.delete();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade100,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: 50),
          Container(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
                SizedBox(width: 50,),
                Text(
                  'My To-Do List',
                  style: TextStyle(
                    fontSize: 40.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16.0),
              child: StreamBuilder<List<Todo>>(
                stream: _todoStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(),
                    );
                  } else if (snapshot.hasError) {
                    return Center(
                      child: Text('Error occurred. Please try again.'),
                    );
                  } else {
                    List<Todo> todos = snapshot.data ?? [];
                    return ListView.builder(
                      itemCount: todos.length,
                      itemBuilder: (context, index) {
                        Todo todo = todos[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8.0),
                          padding: const EdgeInsets.all(8.0),
                          decoration: BoxDecoration(
                            color: Colors.blueGrey.shade100,
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 2,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      todo.title,
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        decoration: todo.completed ? TextDecoration.lineThrough : TextDecoration.none,
                                      ),
                                    ),
                                    Text(
                                      'Due: ${DateFormat.yMd().add_jm().format(todo.due)}', // Display due date and time
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: SizedBox(),
                              ),
                              Checkbox(
                                value: todo.completed,
                                onChanged: (completed) {
                                  _toggleTodoCompletion(todo.id, todo.completed);
                                },
                                activeColor: Colors.green,
                              ),
                              IconButton(
                                icon: Icon(Icons.delete),
                                onPressed: () {
                                  _deleteTodo(todo.id);
                                },
                                color: Colors.red,
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  }
                },
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.blueGrey.shade50,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      TextField(
                        controller: _textEditingController,
                        decoration: InputDecoration(
                          labelText: 'Add task',
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      TextButton(
                        onPressed: () {
                          _selectDueDateAndTime(context); // Use a single function for date and time selection
                        },
                        child: Text('Select Due Date & Time'), // Display due date and time button
                      ),
                      Text(
                        _dueTime == null
                            ? 'No due date selected'
                            : 'Due Date: ${DateFormat.yMd().add_jm().format(_dueTime!)}', // Display selected due date
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    _addTodo();
                  },
                  style: ElevatedButton.styleFrom(
                    primary: Colors.green,
                    onPrimary: Colors.white,
                  ),
                  child: const Text('+'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  DateTime? _dueTime;

  Future<void> _selectDueDateAndTime(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(DateTime.now().year + 5),
    );
    if (picked != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (pickedTime != null) {
        setState(() {
          _dueTime = DateTime(
            picked.year,
            picked.month,
            picked.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  void _addTodo() {
    String title = _textEditingController.text.trim();
    if (title.isNotEmpty && _dueTime != null) {
      _firestore
          .collection('users')
          .doc(_user!.uid)
          .collection('todos')
          .add({
        'title': title,
        'completed': false,
        'due': _dueTime,
      });
      _textEditingController.clear();
      setState(() {
        _dueTime = null;
      });
    }
  }

  void _toggleTodoCompletion(String todoId, bool completed) {
    _firestore
        .collection('users')
        .doc(_user!.uid)
        .collection('todos')
        .doc(todoId)
        .update({
      'completed': !completed,
    });
  }

  void _deleteTodo(String todoId) {
    _firestore
        .collection('users')
        .doc(_user!.uid)
        .collection('todos')
        .doc(todoId)
        .delete();
  }

  @override
  void dispose() {
    _textEditingController.dispose();
    super.dispose();
  }
}

void main() {
  runApp(MaterialApp(
    home: TodoListScreen(),
  ));
}
