import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';


class AssignmentData {
  final String id;
  final String assignmentName;
  final DateTime dueDateTime;
  bool isComplete;

  AssignmentData(this.id, this.assignmentName, this.dueDateTime, this.isComplete);
}

class AssignmentTrackerScreen extends StatefulWidget {
  @override
  _AssignmentTrackerScreenState createState() => _AssignmentTrackerScreenState();
}

class _AssignmentTrackerScreenState extends State<AssignmentTrackerScreen> {
  late String _userId;
  TextEditingController _assignmentNameController = TextEditingController();
  DateTime _selectedDateTime = DateTime.now();
  
  @override
  void initState() {
    super.initState();
    _userId = FirebaseAuth.instance.currentUser!.uid;
  }

  @override
  void dispose() {
    _assignmentNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade100,

      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                SizedBox(height: 30,),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                    SizedBox(width: 16.0),
                    Text(
                      'Assignment Tracker',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(_userId)
                  .collection('assignments')
                  .orderBy('dueDateTime', descending: false)
                  .snapshots(),
              builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final List<AssignmentData> assignments = snapshot.data!.docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final String id = doc.id;
                  final String assignmentName = data['assignmentName'];
                  final Timestamp dueDateTime = data['dueDateTime'];
                  final DateTime dueDateTimeValue = dueDateTime.toDate();
                  final bool isComplete = data['isComplete'] ?? false;
                  return AssignmentData(id, assignmentName, dueDateTimeValue, isComplete);
                }).toList();

                if (assignments.isEmpty) {
                  return Center(
                    child: Text('No assignments found.'),
                  );
                }

                return ListView.separated(
                  separatorBuilder: (context, index) => Divider(),
                  itemCount: assignments.length,
                  itemBuilder: (context, index) {
                    final assignment = assignments[index];

                    return ListTile(
                      title: Text(
                        assignment.assignmentName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Due: ${DateFormat.yMMMd().add_jm().format(assignment.dueDateTime)}',
                          ),
                          Row(
                            children: [
                              Checkbox(
                                value: assignment.isComplete,
                                onChanged: (value) => _updateCompletionStatus(assignment, value!),
                              ),
                              Text('Complete'),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddAssignmentDialog(),
        child: Icon(Icons.add),
      ),
    );
  }

  Future<void> _showAddAssignmentDialog() async {
    final assignmentName = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add Assignment'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _assignmentNameController,
                decoration: InputDecoration(
                  labelText: 'Assignment Name',
                ),
              ),
              SizedBox(height: 16.0),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _selectDueDate(),
                      child: Text('Select Due Date'),
                    ),
                  ),
                  SizedBox(width: 16.0),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _selectDueTime(),
                      child: Text('Select Due Time'),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _addAssignment();
                Navigator.pop(context);
              },
              child: Text('Add'),
            ),
          ],
        );
      },
    );

    _assignmentNameController.clear();
  }

  Future<void> _selectDueDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        _selectedDateTime = DateTime(picked.year, picked.month, picked.day, _selectedDateTime.hour, _selectedDateTime.minute);
      });
    }
  }

  Future<void> _selectDueTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
    );

    if (picked != null) {
      setState(() {
        _selectedDateTime = DateTime(_selectedDateTime.year, _selectedDateTime.month, _selectedDateTime.day, picked.hour, picked.minute);
      });
    }
  }

  Future<void> _addAssignment() async {
    final assignmentName = _assignmentNameController.text.trim();

    if (assignmentName.isNotEmpty) {
      try {
        final docRef = FirebaseFirestore.instance.collection('users').doc(_userId).collection('assignments').doc();
        final assignmentData = AssignmentData(docRef.id, assignmentName, _selectedDateTime, false);

        await docRef.set({
          'assignmentName': assignmentData.assignmentName,
          'dueDateTime': assignmentData.dueDateTime,
          'isComplete': assignmentData.isComplete,
        });
      } catch (e) {
        print('Error adding assignment: $e');
      }
    }
  }

  Future<void> _updateCompletionStatus(AssignmentData assignment, bool value) async {
    try {
      final docRef = FirebaseFirestore.instance.collection('users').doc(_userId).collection('assignments').doc(assignment.id);

      await docRef.update({'isComplete': value});
    } catch (e) {
      print('Error updating completion status: $e');
    }
  }
}
