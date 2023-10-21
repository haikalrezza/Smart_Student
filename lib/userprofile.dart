import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'authenticate.dart';
import 'editprofile.dart';
import 'user.dart';

class UserProfileScreen extends StatelessWidget {
  const UserProfileScreen({Key? key}) : super(key: key);

  Future<void> _signOut(BuildContext context) async {
    try {
      await auth.FirebaseAuth.instance.signOut();
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    } catch (e) {
      print('Sign out failed: $e');
    }
  }

  
  // this method if the user just register and no profile data
  Widget buildNoProfileDataUI(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 150,
          height: 150,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            image: DecorationImage(
              fit: BoxFit.cover,
              image: AssetImage('assets/user.jpg'),
            ),
          ),
        ),
        SizedBox(height: 40),
        Text(
          'Username:',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 5),
        Text(
          'Guest',
          style: TextStyle(fontSize: 16),
        ),
        SizedBox(height: 20),
        Text(
          'Email:',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 5),
        Text(
          FirebaseAuth.instance.currentUser?.email ?? '',
          style: TextStyle(fontSize: 16),
        ),
        SizedBox(height: 40),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            
            SizedBox(width: 16),
            ElevatedButton(
              onPressed: () async {
                User? currentUser = FirebaseAuth.instance.currentUser;
                if (currentUser != null) {
                  String userId = currentUser.uid;

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditProfileScreen(
                        user: Userr(
                          id: userId,
                          name: '',
                          photoUrl: '',
                          university: '',
                          yearOfStudy: '',
                          courseName: '',
                        ),
                      ),
                    ),
                  );
                }
              },
              child: Text('Edit Profile'),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
    final User? currentUser = firebaseAuth.currentUser;
    final CollectionReference usersRef =
    FirebaseFirestore.instance.collection('users');

    return Scaffold(
      body: Container(
        color: Colors.lightGreen.shade50,
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
                SizedBox(width: 40,),


                Text(
                  'My Profile',
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(width: 40,),

                IconButton(
                  icon: Icon(Icons.logout),
                  onPressed: () {
                    _signOut(context);
                    Navigator.pop(context);
                  },
                ),

              ],
            ),
            SizedBox(height: 40),
            StreamBuilder<DocumentSnapshot>(
              stream: usersRef
                  .doc(currentUser!.uid)
                  .collection('userprofile')
                  .doc('profile')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                }
                if (!snapshot.hasData || snapshot.data == null) {
                  return buildNoProfileDataUI(context);
                }

                final data =
                snapshot.data!.data() as Map<String, dynamic>?;

                if (data != null) {
                  final String name = data['name'] ?? '';
                  final String photoUrl = data['photoUrl'] ?? '';
                  final String university = data['university'] ?? '';
                  final String yearOfStudy = data['yearOfStudy'] ?? '';
                  final String courseName = data['courseName'] ?? '';

                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          image: DecorationImage(
                            fit: BoxFit.cover,
                            image: photoUrl.isNotEmpty
                                ? NetworkImage(photoUrl)
                                : const AssetImage('assets/user.jpg')
                            as ImageProvider,
                          ),
                        ),
                      ),
                      SizedBox(height: 40),
                      _buildProfileField('Username:', name.isNotEmpty ? name : 'Guest'),
                      SizedBox(height: 20),
                      _buildProfileField('Email:', currentUser.email ?? ''),
                      SizedBox(height: 20),
                      _buildProfileField('University:', university.isNotEmpty ? university : 'Not specified'),
                      SizedBox(height: 20),
                      _buildProfileField('Year of Study:', yearOfStudy.isNotEmpty ? yearOfStudy : 'Not specified'),
                      SizedBox(height: 20),
                      _buildProfileField('Course:', courseName.isNotEmpty ? courseName : 'Not specified'),
                      SizedBox(height: 40),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [

                          SizedBox(width: 16),
                          ElevatedButton(
                            onPressed: () async {
                              if (currentUser != null) {
                                String userId = currentUser.uid;

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EditProfileScreen(
                                      user: Userr(
                                        id: userId,
                                        name: '',
                                        photoUrl: '',
                                        university: university,
                                        yearOfStudy: yearOfStudy,
                                        courseName: courseName,
                                      ),
                                    ),
                                  ),
                                );
                              }
                            },
                            child: Text('Edit Profile'),
                          ),
                        ],
                      ),
                    ],
                  );
                } else {
                  return buildNoProfileDataUI(context);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileField(String label, String value) {
    return Container(
      padding: EdgeInsets.all(12),
      margin: EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 2,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
