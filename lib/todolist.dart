import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Todo {
  final String id;
  final String title;
  final bool completed;

  Todo({
    required this.id,
    required this.title,
    required this.completed,
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
        );
      }).toList();
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
                  'My To Do List',
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
                          child: ListTile(
                            title: Text(
                              todo.title,
                              style: TextStyle(
                                color: Colors.black,
                                decoration: todo.completed
                                    ? TextDecoration.lineThrough
                                    : TextDecoration.none,
                              ),
                            ),
                            leading: Checkbox(
                              value: todo.completed,
                              onChanged: (completed) {
                                _toggleTodoCompletion(todo.id, todo.completed);
                              },
                              activeColor: Colors.green,
                            ),
                            trailing: IconButton(
                              icon: Icon(Icons.delete),
                              onPressed: () {
                                _deleteTodo(todo.id);
                              },
                              color: Colors.red,
                            ),
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
                  child: TextField(
                    controller: _textEditingController,
                    decoration: InputDecoration(
                      labelText: 'Add task',
                    ),
                  ),
                ),
                SizedBox(width: 16.0),
                ElevatedButton(
                  onPressed: _addTodo,
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

  void _addTodo() {
    String title = _textEditingController.text.trim();
    if (title.isNotEmpty) {
      _firestore
          .collection('users')
          .doc(_user!.uid)
          .collection('todos')
          .add({
        'title': title,
        'completed': false,
      });
      _textEditingController.clear();
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
