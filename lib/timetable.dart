import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class ClassData {
  final String id;
  final String className;
  final String lecturer;
  final String venue;
  final String day;
  final DateTime startTime;
  final DateTime endTime;

  ClassData(this.id, this.className, this.lecturer, this.venue, this.day, this.startTime, this.endTime);
}

class TimetableScreen extends StatefulWidget {
  @override
  _TimetableScreenState createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  late String _userId;
  late String _currentDay;
  late PageController _pageController;
  String selectedTimeSlot = '8:00 AM - 10:00 AM'; // Initialize with the first time slot

  @override
  void initState() {
    super.initState();
    _userId = FirebaseAuth.instance.currentUser!.uid;

    // Get the current day and format it as a lowercase string
    _currentDay = DateFormat('EEEE').format(DateTime.now()).toLowerCase();
    print(_currentDay);

    _pageController = PageController(initialPage: _getCurrentDayIndex());
  }

  int _getCurrentDayIndex() {
    switch (_currentDay) {
      case 'monday':
        return 0;
      case 'tuesday':
        return 1;
      case 'wednesday':
        return 2;
      case 'thursday':
        return 3;
      case 'friday':
        return 4;
      case 'saturday':
        return 5;
      case 'sunday':
        return 6;
      default:
        return 0;
    }
  }

  String _getDayFromIndex(int index) {
    switch (index) {
      case 0:
        return 'monday';
      case 1:
        return 'tuesday';
      case 2:
        return 'wednesday';
      case 3:
        return 'thursday';
      case 4:
        return 'friday';
      case 5:
        return 'saturday';
      case 6:
        return 'sunday';
      default:
        return 'monday';
    }
  }

  void _setCurrentDay(int index) {
    setState(() {
      _currentDay = _getDayFromIndex(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade100,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: 39),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
              SizedBox(width: 80,),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  _currentDay.toUpperCase() ,
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) {
                      return Dialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.0),
                        ),
                        child: Container(
                          padding: EdgeInsets.all(16.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Tips',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 16),
                              Text('Swipe your screen to change between day'), // Replace with your desired tips content
                              SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: Text('OK'),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
                child: Icon(
                  Icons.info_outline,
                  size: 20,
                ),
              ),
            ],
          ),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                _setCurrentDay(index);
              },
              itemCount: 7,
              itemBuilder: (context, index) {
                final day = _getDayFromIndex(index);
                return TimetablePage(day: day, userId: _userId);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) {
              String className = '';
              String lecturer = '';
              String venue = '';
              String selectedTimeSlot = '8:00 AM - 10:00 AM'; // Initialize with the first time slot

              return StatefulBuilder(
                builder: (context, setState) {
                  return AlertDialog(
                    title: Text('Add Class'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          decoration: InputDecoration(labelText: 'Class Name'),
                          onChanged: (value) => className = value,
                        ),
                        TextField(
                          decoration: InputDecoration(labelText: 'Lecturer'),
                          onChanged: (value) => lecturer = value,
                        ),
                        TextField(
                          decoration: InputDecoration(labelText: 'Venue'),
                          onChanged: (value) => venue = value,
                        ),
                        SizedBox(height: 16),
                        Text('Day:'),
                        DropdownButton<String>(
                          value: _currentDay,
                          onChanged: (newValue) {
                            setState(() {
                              _currentDay = newValue!;
                            });
                          },
                          items: <String>[
                            'monday',
                            'tuesday',
                            'wednesday',
                            'thursday',
                            'friday',
                            'saturday',
                            'sunday',
                          ].map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value.toUpperCase()),
                            );
                          }).toList(),
                        ),
                        SizedBox(height: 16),
                        Text('Time Slot:'),
                        DropdownButton<String>(
                          value: selectedTimeSlot,
                          onChanged: (newValue) {
                            setState(() {
                              selectedTimeSlot = newValue!;
                            });
                          },
                          items: [
                            '8:00 AM - 10:00 AM',
                            '10:00 AM - 12:00 PM',
                            '01:00 PM - 03:00 PM',
                            '03:00 PM - 05:00 PM',
                          ].map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          if (className.isNotEmpty && lecturer.isNotEmpty && venue.isNotEmpty) {
                            // Convert selectedTimeSlot to start and end times
                            final List<String> selectedTimeSlotParts = selectedTimeSlot.split(' - ');
                            final String selectedStartTime = selectedTimeSlotParts[0];
                            final String selectedEndTime = selectedTimeSlotParts[1];

                            // Parse the time with am/pm
                            final DateFormat dateFormat = DateFormat('hh:mm a');
                            final DateTime startTime = dateFormat.parse(selectedStartTime);
                            final DateTime endTime = dateFormat.parse(selectedEndTime);

                            _addClass(className, lecturer, venue, _currentDay, startTime, endTime);

                            Navigator.pop(context);
                          }
                        },
                        child: Text('Add'),
                      ),


                    ],
                  );
                },
              );
            },
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }

  Future<void> _addClass(String className, String lecturer, String venue, String day, DateTime startTime, DateTime endTime) async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(_userId)
        .collection('timetable')
        .where('day', isEqualTo: day)
        .get();

    int newStartTimeMinutes = startTime.hour * 60 + startTime.minute;
    int newEndTimeMinutes = endTime.hour * 60 + endTime.minute;

    bool isInterference = false;

    querySnapshot.docs.forEach((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final existingStartTime = (data['startTime'] as Timestamp).toDate();
      final existingEndTime = (data['endTime'] as Timestamp).toDate();

      int existingStartTimeMinutes = existingStartTime.hour * 60 + existingStartTime.minute;
      int existingEndTimeMinutes = existingEndTime.hour * 60 + existingEndTime.minute;

      // Check if the new class interferes with an existing class
      if ((newStartTimeMinutes >= existingStartTimeMinutes && newStartTimeMinutes < existingEndTimeMinutes) ||
          (newEndTimeMinutes > existingStartTimeMinutes && newEndTimeMinutes <= existingEndTimeMinutes) ||
          (newStartTimeMinutes <= existingStartTimeMinutes && newEndTimeMinutes >= existingEndTimeMinutes)) {
        isInterference = true;
      }
    });

    if (isInterference) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Error Adding Class'),
            content: Text('You cannot add a class that interferes with an existing class on the same day and time slot.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text('OK'),
              ),
            ],
          );
        },
      );
    } else {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .collection('timetable')
          .add({
        'className': className,
        'lecturer': lecturer,
        'venue': venue,
        'day': day,
        'startTime': startTime,
        'endTime': endTime,
      });

      // Close the dialog
      print('Class added');
    }
  }

}

class TimetablePage extends StatelessWidget {
  final String day;
  final String userId;

  TimetablePage({required this.day, required this.userId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('timetable')
          .where('day', isEqualTo: day)
          .orderBy('startTime', descending: false)
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

        final List<ClassData> classes = snapshot.data!.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return ClassData(
            doc.id,
            data['className'],
            data['lecturer'],
            data['venue'],
            data['day'],
            data['startTime'].toDate(),
            data['endTime'].toDate(),
          );
        }).toList();

        if (classes.isEmpty) {
          return Center(
            child: Text('No classes found for $day.'),
          );
        }

        return ListView.separated(
          separatorBuilder: (context, index) => Divider(),
          itemCount: classes.length,
          itemBuilder: (context, index) {
            final classData = classes[index];
            final startTime = DateFormat.jm().format(classData.startTime);
            final endTime = DateFormat.jm().format(classData.endTime);
            final isCurrentClass = _isCurrentClass(classData);

            return Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(16.0),
                color: isCurrentClass ? Colors.green : Colors.blueGrey.shade100, // Highlight current class
              ),
              child: ListTile(
                title: Row(
                  children: [
                    Icon(Icons.class_, size: 20,), // Person logo
                    SizedBox(width: 8),
                    Text(
                      classData.className,
                      style: TextStyle(
                          fontWeight: isCurrentClass ? FontWeight.bold : FontWeight.normal, fontSize: isCurrentClass ? 30 : 20
                      ),
                    ),
                    if (isCurrentClass)
                      Container(
                        margin: EdgeInsets.only(left: 8),
                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.shade600,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Now',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.person, size: 13,), // Location pinpoint logo
                        SizedBox(width: 4),
                        Text(classData.lecturer),
                      ],
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.access_time,size: 13,), // Clock logo
                        SizedBox(width: 4),
                        Text('$startTime - $endTime'),
                      ],
                    ),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 13,), // Location pinpoint logo
                        SizedBox(width: 4),
                        Text(classData.venue),
                      ],
                    ),
                  ],
                ),
                trailing: IconButton(
                  icon: Icon(Icons.delete_forever),
                  onPressed: () => _deleteClass(classData),
                ),
              ),
            );
          },
        );
      },
    );
  }

  bool _isCurrentClass(ClassData classData) {
    final currentday = DateFormat('EEEE').format(DateTime.now()).toLowerCase();
    final now = DateTime.now();
    final startTime = DateTime(
      now.year,
      now.month,
      now.day,
      classData.startTime.hour,
      classData.startTime.minute,
    );
    final endTime = DateTime(
      now.year,
      now.month,
      now.day,
      classData.endTime.hour,
      classData.endTime.minute,
    );

    return classData.day == currentday && startTime.isBefore(now) && endTime.isAfter(now);
  }

  void _deleteClass(ClassData classData) {
    FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('timetable')
        .doc(classData.id)
        .delete()
        .then((value) => print('Class deleted'))
        .catchError((error) => print('Failed to delete class: $error'));
  }
}

void main() {
  runApp(MaterialApp(
    home: Scaffold(
      body: TimetableScreen(),
    ),
  ));
}
