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


              ), GestureDetector(
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
              TimeOfDay selectedStartTime = TimeOfDay.now();
              TimeOfDay selectedEndTime = TimeOfDay.fromDateTime(DateTime.now().add(Duration(hours: 1)));
              String selectedDay = _currentDay; // Initialize with the current day

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
                          value: selectedDay,
                          onChanged: (newValue) {
                            setState(() {
                              selectedDay = newValue!;
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
                        Row(
                          children: [
                            Text('Start:'),
                            Container(
                              margin: EdgeInsets.symmetric(horizontal: 8),
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size(40, 40),
                                ),
                                onPressed: () async {
                                  final TimeOfDay? pickedTime = await showTimePicker(
                                    context: context,
                                    initialTime: selectedStartTime,
                                  );
                                  if (pickedTime != null) {
                                    setState(() {
                                      selectedStartTime = pickedTime;
                                    });
                                  }
                                },
                                child: Text(selectedStartTime.format(context)),
                              ),
                            ),
                            SizedBox(height: 16),
                            Text('End:'),
                            Container(
                              margin: EdgeInsets.symmetric(horizontal: 8),
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size(40, 40),
                                ),
                                onPressed: () async {
                                  final TimeOfDay? pickedTime = await showTimePicker(
                                    context: context,
                                    initialTime: selectedEndTime,
                                  );
                                  if (pickedTime != null) {
                                    if (pickedTime.hour > selectedStartTime.hour ||
                                        (pickedTime.hour == selectedStartTime.hour && pickedTime.minute > selectedStartTime.minute)) {
                                      setState(() {
                                        selectedEndTime = pickedTime;
                                      });
                                    } else {
                                      showDialog(
                                        context: context,
                                        builder: (context) {
                                          return AlertDialog(
                                            title: Text('Invalid Time'),
                                            content: Text('The end time must be after the start time.'),
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
                                    }
                                  }
                                },
                                child: Text(selectedEndTime.format(context)),
                              ),
                            ),
                          ],
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
                            final DateTime startTime = DateTime(
                              DateTime.now().year,
                              DateTime.now().month,
                              DateTime.now().day,
                              selectedStartTime.hour,
                              selectedStartTime.minute,
                            );
                            final DateTime endTime = DateTime(
                              DateTime.now().year,
                              DateTime.now().month,
                              DateTime.now().day,
                              selectedEndTime.hour,
                              selectedEndTime.minute,
                            );

                            _addClass(className, lecturer, venue, selectedDay, startTime, endTime);

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

  void _addClass(String className, String lecturer, String venue, String day, DateTime startTime, DateTime endTime) {
    FirebaseFirestore.instance
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
    })
        .then((value) => print('Class added'))
        .catchError((error) => print('Failed to add class: $error'));
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
    final isCurrentDay = classData.day.toLowerCase() == currentday;

    return isCurrentDay && now.isAfter(classData.startTime) && now.isBefore(classData.endTime);
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
    home: TimetableScreen(),
  ));
}






















// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:intl/intl.dart';
//
// class ClassData {
//   final String id;
//   final String className;
//   final String lecturer;
//   final String venue;
//   final String day;
//   final DateTime startTime;
//   final DateTime endTime;
//
//   ClassData(this.id, this.className, this.lecturer, this.venue, this.day, this.startTime, this.endTime);
// }
//
// class TimetableScreen extends StatefulWidget {
//   @override
//   _TimetableScreenState createState() => _TimetableScreenState();
// }
//
// class _TimetableScreenState extends State<TimetableScreen> {
//   late String _userId;
//   late String _currentDay;
//
//   @override
//   void initState() {
//     super.initState();
//     _userId = FirebaseAuth.instance.currentUser!.uid;
//
//     // Get the current day and format it as a lowercase string
//     _currentDay = DateFormat('EEEE').format(DateTime.now()).toLowerCase();
//     print(_currentDay);
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Class Timetable'),
//       ),
//       body: StreamBuilder<QuerySnapshot>(
//         stream: FirebaseFirestore.instance
//             .collection('users')
//             .doc(_userId)
//             .collection('timetable')
//             .where('day', isEqualTo: _currentDay)
//             .orderBy('startTime', descending: false)
//             .snapshots(),
//         builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
//           if (snapshot.hasError) {
//             return Center(
//               child: Text('Error: ${snapshot.error}'),
//             );
//           }
//
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return Center(
//               child: CircularProgressIndicator(),
//             );
//           }
//
//           final List<ClassData> classes = snapshot.data!.docs.map((doc) {
//             final data = doc.data() as Map<String, dynamic>;
//             return ClassData(
//               doc.id,
//               data['className'],
//               data['lecturer'],
//               data['venue'],
//               data['day'],
//               data['startTime'].toDate(),
//               data['endTime'].toDate(),
//             );
//           }).toList();
//
//           if (classes.isEmpty) {
//             return Center(
//               child: Text('No classes found for $_currentDay.'),
//             );
//           }
//
//           return ListView.separated(
//             separatorBuilder: (context, index) => Divider(),
//             itemCount: classes.length,
//             itemBuilder: (context, index) {
//               final classData = classes[index];
//               final startTime = DateFormat.jm().format(classData.startTime);
//               final endTime = DateFormat.jm().format(classData.endTime);
//
//               return ListTile(
//                 title: Text(classData.className),
//                 subtitle: Text('$startTime - $endTime\n${classData.venue}'),
//                 trailing: IconButton(
//                   icon: Icon(Icons.delete),
//                   onPressed: () => _deleteClass(classData),
//                 ),
//               );
//             },
//           );
//         },
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: () {
//           showDialog(
//             context: context,
//             builder: (context) {
//               String className = '';
//               String lecturer = '';
//               String venue = '';
//               TimeOfDay selectedStartTime = TimeOfDay.now();
//               TimeOfDay selectedEndTime = TimeOfDay.now();
//               String selectedDay = _currentDay; // Initialize with the current day
//
//               return StatefulBuilder(
//                 builder: (context, setState) {
//                   return AlertDialog(
//                     title: Text('Add Class'),
//                     content: Column(
//                       mainAxisSize: MainAxisSize.min,
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         TextField(
//                           decoration: InputDecoration(labelText: 'Class Name'),
//                           onChanged: (value) => className = value,
//                         ),
//                         TextField(
//                           decoration: InputDecoration(labelText: 'Lecturer'),
//                           onChanged: (value) => lecturer = value,
//                         ),
//                         TextField(
//                           decoration: InputDecoration(labelText: 'Venue'),
//                           onChanged: (value) => venue = value,
//                         ),
//                         SizedBox(height: 16),
//                         Text('Day:'),
//                         DropdownButton<String>(
//                           value: selectedDay,
//                           onChanged: (newValue) {
//                             setState(() {
//                               selectedDay = newValue!;
//                             });
//                           },
//                           items: <String>[
//                             'monday',
//                             'tuesday',
//                             'wednesday',
//                             'thursday',
//                             'friday',
//                             'saturday',
//                             'sunday',
//                           ].map<DropdownMenuItem<String>>((String value) {
//                             return DropdownMenuItem<String>(
//                               value: value,
//                               child: Text(value.toUpperCase()),
//                             );
//                           }).toList(),
//                         ),
//                         SizedBox(height: 16),
//                         Text('Start Time:'),
//                         ElevatedButton(
//                           onPressed: () async {
//                             final TimeOfDay? pickedTime = await showTimePicker(
//                               context: context,
//                               initialTime: selectedStartTime,
//                             );
//                             if (pickedTime != null) {
//                               setState(() {
//                                 selectedStartTime = pickedTime;
//                               });
//                             }
//                           },
//                           child: Text(selectedStartTime.format(context)),
//                         ),
//                         SizedBox(height: 16),
//                         Text('End Time:'),
//                         ElevatedButton(
//                           onPressed: () async {
//                             final TimeOfDay? pickedTime = await showTimePicker(
//                               context: context,
//                               initialTime: selectedEndTime,
//                             );
//                             if (pickedTime != null) {
//                               setState(() {
//                                 selectedEndTime = pickedTime;
//                               });
//                             }
//                           },
//                           child: Text(selectedEndTime.format(context)),
//                         ),
//                       ],
//                     ),
//                     actions: [
//                       TextButton(
//                         onPressed: () {
//                           Navigator.pop(context);
//                         },
//                         child: Text('Cancel'),
//                       ),
//                       TextButton(
//                         onPressed: () {
//                           if (className.isNotEmpty && lecturer.isNotEmpty && venue.isNotEmpty) {
//                             final DateTime startTime = DateTime(
//                               DateTime.now().year,
//                               DateTime.now().month,
//                               DateTime.now().day,
//                               selectedStartTime.hour,
//                               selectedStartTime.minute,
//                             );
//                             final DateTime endTime = DateTime(
//                               DateTime.now().year,
//                               DateTime.now().month,
//                               DateTime.now().day,
//                               selectedEndTime.hour,
//                               selectedEndTime.minute,
//                             );
//
//                             FirebaseFirestore.instance
//                                 .collection('users')
//                                 .doc(_userId)
//                                 .collection('timetable')
//                                 .add({
//                               'className': className,
//                               'lecturer': lecturer,
//                               'venue': venue,
//                               'day': selectedDay.toLowerCase(), // Save the day in lowercase
//                               'startTime': startTime,
//                               'endTime': endTime,
//                             });
//                           }
//
//                           Navigator.pop(context);
//                         },
//                         child: Text('Add'),
//                       ),
//                     ],
//                   );
//                 },
//               );
//             },
//           );
//         },
//         child: Icon(Icons.add),
//       ),
//     );
//   }
//
//   void _deleteClass(ClassData classData) {
//     showDialog(
//       context: context,
//       builder: (context) {
//         return AlertDialog(
//           title: Text('Delete Class'),
//           content: Text('Are you sure you want to delete this class?'),
//           actions: [
//             TextButton(
//               onPressed: () {
//                 Navigator.pop(context);
//               },
//               child: Text('Cancel'),
//             ),
//             TextButton(
//               onPressed: () {
//                 FirebaseFirestore.instance
//                     .collection('users')
//                     .doc(_userId)
//                     .collection('timetable')
//                     .doc(classData.id)
//                     .delete();
//                 Navigator.pop(context);
//               },
//               child: Text('Delete'),
//             ),
//           ],
//         );
//       },
//     );
//   }
// }
