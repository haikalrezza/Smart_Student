import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'bitc.dart';
import 'bitm.dart';
import 'bitz.dart';
import 'bits.dart';
import 'user.dart';

class EditProfileScreen extends StatefulWidget {
  final Userr user;

  EditProfileScreen({required this.user});

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _universityController;
  late TextEditingController _yearOfStudyController;
  String _selectedCourse = ''; // Default course option
  File? _selectedImage;
  bool _isUploading = false;
  bool _isEditingName = false;
  String? _photoUrl;
  bool _isCourseNameMissing = false;

  final List<String> _courseOptions = ['','Bachelor of Computer Science (Software Development) with Honours', 'Bachelor of Computer Science (Computer Security) with Honours', 'Bachelor of Computer Science (Computer Neworking) with Honours', 'Bachelor of Computer Science (Interactive Media) with Honours'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _universityController = TextEditingController();
    _yearOfStudyController = TextEditingController();
    _fetchProfileData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _universityController.dispose();
    _yearOfStudyController.dispose();
    super.dispose();
  }

  Future<void> _fetchProfileData() async {
    final DocumentSnapshot profileSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.user.id)
        .collection('userprofile')
        .doc('profile')
        .get();

    if (profileSnapshot.exists) {
      final profileData = profileSnapshot.data() as Map<String, dynamic>?;
      final name = profileData?['name'] as String?;
      final university = profileData?['university'] as String?;
      final yearOfStudy = profileData?['yearOfStudy'] as String?;
      final courseName = profileData?['courseName'] as String?;
      final photoUrl = profileData?['photoUrl'] as String?;

      if (name != null) {
        setState(() {
          _nameController.text = name;
        });
      }
      if (university != null) {
        setState(() {
          _universityController.text = university;
        });
      }
      if (yearOfStudy != null) {
        setState(() {
          _yearOfStudyController.text = yearOfStudy;
        });
      }
      if (courseName == null || courseName.isEmpty) {
        // Course name is missing or not defined
        setState(() {
          _isCourseNameMissing = true;
        });
      } else {
        // Course name is defined
        setState(() {
          _selectedCourse = courseName;
        });
      }
      if (photoUrl != null && photoUrl.isNotEmpty) {
        setState(() {
          _photoUrl = photoUrl;
        });
      }
    }
  }

  Future<void> _selectImage() async {
    final picker = ImagePicker();
    final pickedImage = await picker.getImage(
      source: ImageSource.gallery,
      imageQuality: 20,
    );
    if (pickedImage != null) {
      setState(() {
        _photoUrl = null; // Reset the existing photo URL
        _selectedImage = File(pickedImage.path);
        _uploadProfilePhoto(); // Upload the selected image
      });
    }
  }

  Future<String> _uploadProfilePhoto() async {
    final Reference storageRef = FirebaseStorage.instance
        .ref()
        .child('profile_photos')
        .child('${widget.user.id}.jpg');

    final UploadTask uploadTask = storageRef.putFile(_selectedImage!);

    final TaskSnapshot uploadSnapshot = await uploadTask.whenComplete(() {});
    final String downloadUrl = await uploadSnapshot.ref.getDownloadURL();

    setState(() {
      _isUploading = false;
    });

    return downloadUrl;
  }

  Future<void> _deleteExistingSubjects(String userId) async {
    final QuerySnapshot subjectsSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('cgpa')
        .get();

    final List<Future<void>> deleteTasks = [];

    for (QueryDocumentSnapshot doc in subjectsSnapshot.docs) {
      deleteTasks.add(doc.reference.delete());
    }

    await Future.wait(deleteTasks);
  }


  Future<void> _predefined() async {



    final List<String> allSemesters = [
      'Year One : Semester 1',
      'Year One : Semester 2',
      'Year Two : Semester 1',
      'Year Two : Semester 2',
      'Year Three : Semester 1',
      'Year Three : Semester 2',
      'Year Three : Special Semester',
      'Year Four : Semester 1',
    ];

    final FirebaseAuth _auth = FirebaseAuth.instance;
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;

    final User? user = _auth.currentUser;
    final userId = user!.uid;
    final List<Future<void>> addSubjectTasks = [];

    await _deleteExistingSubjects(userId);


    for (final semester in allSemesters) {
      final DocumentReference semesterDocRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('cgpa')
          .doc(semester);
      await semesterDocRef.set({'Semester': semester}, SetOptions(merge: true));
      final subjectsForSemester = _getSubjectsForSelectedCourse(semester);

      if (subjectsForSemester != null) {
        for (final subjectData in subjectsForSemester) {
          addSubjectTasks.add(semesterDocRef.collection('subjects').add(subjectData));
        }
      }

      await Future.wait(addSubjectTasks);
      print('Predefined subjects added for all semesters');
    }
  }

  List<Map<String, dynamic>>? _getSubjectsForSelectedCourse(String semester) {
    switch (_selectedCourse) {
      case 'Bachelor of Computer Science (Computer Security) with Honours':
        return bitz[semester];
      case 'Bachelor of Computer Science (Computer Networking) with Honours':
        return bitc[semester];
      case 'Bachelor of Computer Science (Interactive Media) with Honours':
        return bitm[semester];
      case 'Bachelor of Computer Science (Software Development) with Honours':
        return bits[semester];
      default:
        return bits[semester];

    }
  }

  Future<void> _saveProfileChanges() async {
    final DocumentReference userRef = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.user.id)
        .collection('userprofile')
        .doc('profile');

    String photoUrl = _photoUrl ?? '';

    if (_selectedImage != null) {
      photoUrl = await _uploadProfilePhoto();
    }

    Map<String, dynamic> profileData = {
      'name': _nameController.text,
      'photoUrl': photoUrl,
      'university': _universityController.text,
      'yearOfStudy': _yearOfStudyController.text,
      'courseName': _selectedCourse,
    };

    await userRef.set(profileData);

    Navigator.pop(context);
    // Show a success message or navigate to a different screen
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              SizedBox(
                height: 30,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  IconButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    icon: Icon(Icons.arrow_back),
                  ),
                  Text(
                    'Edit Profile',
                    style: TextStyle(
                      fontSize: 35.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: 49,
              ),
              GestureDetector(
                onTap: _selectImage,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 80.0,
                      height: 80.0,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.black,
                          width: 2.0,
                        ),
                      ),
                      child: ClipOval(
                        child: _photoUrl != null && _photoUrl!.isNotEmpty
                            ? Image.network(
                          _photoUrl!,
                          width: 80.0,
                          height: 80.0,
                          fit: BoxFit.cover,
                        )
                            : _selectedImage != null
                            ? Image.file(
                          _selectedImage!,
                          width: 80.0,
                          height: 80.0,
                          fit: BoxFit.cover,
                        )
                            : Image.asset(
                          'assets/user.jpg',
                          width: 80.0,
                          height: 80.0,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    if (_isUploading)
                      CircularProgressIndicator(
                        valueColor:
                        AlwaysStoppedAnimation<Color>(Colors.black),
                      ),
                  ],
                ),
              ),
              SizedBox(height: 8.0),
              Text(
                'Tap the profile photo to change it',
                style: TextStyle(fontSize: 12.0),
              ),
              SizedBox(height: 16.0),
              if (_isEditingName)
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          _isEditingName = false;
                        });
                      },
                      icon: Icon(Icons.check),
                    ),
                  ),
                )
              else
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isEditingName = true;
                    });
                  },
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.black,
                        width: 2.0,
                      ),
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _nameController.text,
                            style: TextStyle(fontSize: 18.0),
                          ),
                        ),
                        Icon(Icons.edit),
                      ],
                    ),
                  ),
                ),
              SizedBox(height: 16.0),
              TextFormField(
                controller: _universityController,
                decoration: InputDecoration(
                  labelText: 'University',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16.0),

              SizedBox(height: 16.0),
              if (_isCourseNameMissing)
                Column(
                  children: [
                    SizedBox(height: 16.0),
                    Text('Please select your course:'),
                    DropdownButton<String>(
                      value: _selectedCourse,
                      onChanged: (newValue) {
                        setState(() {
                          _selectedCourse = newValue!;
                        });
                      },
                      items: _courseOptions.map<DropdownMenuItem<String>>(
                            (value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        },
                      ).toList(),
                    ),
                    SizedBox(height: 16.0),
                    FloatingActionButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Text('Confirmation'),
                              content: Text(
                                'Course Name can only be set once! Are you sure you want to proceed?',
                              ),
                              actions: <Widget>[
                                TextButton(
                                  child: Text('Cancel'),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                ),
                                TextButton(
                                  child: Text('Proceed'),
                                  onPressed: () {
                                    Navigator.of(context).pop(); // Close the dialog
                                    _predefined(); // Call the _predefined function
                                  },
                                ),
                              ],
                            );
                          },
                        );
                      },
                      child: Icon(Icons.system_update_tv_outlined), // You can change this icon to any other icon you like
                      backgroundColor: Colors.green[100],
                      mini: true,// Set the background color for the FAB
                    ),

                  ],
                ),
              SizedBox(height: 70),
              ElevatedButton(
                onPressed: _saveProfileChanges,
                child: Text('Save Changes'),
              ),
             
            ],
          ),
        ),
      ),
    );
  }
}
