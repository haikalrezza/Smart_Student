import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'webview.dart';
import 'pomodoro.dart';
import 'todolist.dart';
import 'userprofile.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'timetable.dart';
import 'assignmenttracker.dart';
import 'cgpa.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
    final User? currentUser = firebaseAuth.currentUser;
    final CollectionReference usersRef =
    FirebaseFirestore.instance.collection('users');

    String _getGreeting() {
      final hour = DateTime.now().hour;
      if (hour >= 5 && hour < 12) {
        return 'Good Morning ☀';
      } else if (hour >= 12 && hour < 18) {
        return 'Good Afternoon ☀';
      } else {
        return 'Good Night ☽';
      }
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.green.shade300,
              borderRadius: const BorderRadius.only(
                bottomRight: Radius.circular(50),
              ),
            ),
            child: Column(
              children: [
                const SizedBox(height: 50),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 30),
                  title: StreamBuilder<DocumentSnapshot>(
                    stream: usersRef
                        .doc(currentUser?.uid ?? '')
                        .collection('userprofile')
                        .doc('profile')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        final data =
                        snapshot.data!.data() as Map<String, dynamic>?;

                        if (data != null) {
                          final String username = data['name'] ?? '';

                          if (username.isNotEmpty) {
                            return Text(
                              'Hello $username!',
                              style: Theme.of(context).textTheme.headline6?.copyWith(
                                color: Colors.black,
                                fontSize: 24.0,
                              ),
                            );

                          }
                        }
                      }

                      return Text(
                        'Hello Guest!',
                        style: Theme.of(context).textTheme.headline6?.copyWith(
                          color: Colors.black,
                          fontSize: 24.0,
                        ),

                      );
                    },
                  ),
                  subtitle: Text(
                    _getGreeting(),
                    style: Theme.of(context).textTheme.headline6?.copyWith(
                      color: Colors.black26,
                      fontSize: 20.0,
                    ),
                  ),
                  trailing: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => UserProfileScreen(),
                        ),
                      );
                    },
                    child: StreamBuilder<DocumentSnapshot>(
                      stream: usersRef
                          .doc(currentUser?.uid ?? '')
                          .collection('userprofile')
                          .doc('profile')
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          final data =
                          snapshot.data!.data() as Map<String, dynamic>?;

                          if (data != null) {
                            final String photoUrl = data['photoUrl'] ?? '';

                            if (photoUrl.isNotEmpty) {
                              return CircleAvatar(
                                radius: 30,
                                backgroundImage: NetworkImage(photoUrl),
                              );
                            }
                          }
                        }

                        return CircleAvatar(
                          radius: 30,
                          backgroundImage: AssetImage('assets/user.jpg'),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
          Container(
            color: Colors.green.shade300,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                  BorderRadius.only(topLeft: Radius.circular(200))),
              child: GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 40,
                mainAxisSpacing: 30,
                children: [
                  itemDashboard(
                    context,
                    'Schedule',
                    CupertinoIcons.table_badge_more,
                    Colors.lightBlue,
                        () {

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TimetableScreen(),
                            ),
                          );
                      // Handle Schedule onTap
                    },
                  ),
                  itemDashboard(
                    context,
                    'To-Do-List',
                    CupertinoIcons.list_bullet,
                    Colors.green,
                        () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TodoListScreen(),
                        ),
                      );
                      // Handle To-Do-List onTap
                    },
                  ),
                  itemDashboard(
                    context,
                    'Assignment Tracker',
                    CupertinoIcons.square_list,
                    Colors.purple,
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AssignmentTrackerScreen(),
                            ),
                          );
                      // Handle Assignment Tracker onTap
                    },
                  ),
                  itemDashboard(
                    context,
                    'Pomodoro Timer',
                    CupertinoIcons.timer,
                    Colors.brown,
                        () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PomodoroScreen(),
                        ),
                      );
                      // Handle Pomodoro Timer onTap
                    },
                  ),
                  itemDashboard(
                    context,
                    'CGPA Calculator',
                    CupertinoIcons.pencil,
                    Colors.indigo,
                        () {

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => GPAInputScreen(),
                            ),
                          );
                      // Handle CGPA Calculator onTap
                    },
                  ),
                  itemDashboard(
                    context,
                    'E-Learning',
                    CupertinoIcons.book_fill,
                    Colors.teal,
                        () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => WebViewApp(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  GestureDetector itemDashboard(
      BuildContext context,
      String title,
      IconData iconData,
      Color background,
      void Function()? onTap,
      ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.blueGrey.shade100,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              offset: const Offset(0, 5),
              color: Theme.of(context).primaryColor.withOpacity(.2),
              spreadRadius: 3,
              blurRadius: 7,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: background,
                shape: BoxShape.circle,
              ),
              child: Icon(iconData, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 12.0, // Adjust the font size as desired
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
