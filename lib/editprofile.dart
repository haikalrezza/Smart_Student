import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  late TextEditingController _courseNameController;

  File? _selectedImage;
  bool _isUploading = false;
  bool _isEditingName = false;
  String? _photoUrl;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _universityController = TextEditingController();
    _yearOfStudyController = TextEditingController();
    _courseNameController = TextEditingController();
    _fetchProfileData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _universityController.dispose();
    _yearOfStudyController.dispose();
    _courseNameController.dispose();
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
      if (courseName != null) {
        setState(() {
          _courseNameController.text = courseName;
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
    // setState(() {
    //   _isUploading = true;
    // });

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
      'courseName': _courseNameController.text,
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
              SizedBox(height: 30,),
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
              SizedBox(height: 49,),
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
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
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
              TextFormField(
                controller: _yearOfStudyController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: 'Year of Study',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16.0),
              TextFormField(
                controller: _courseNameController,
                decoration: InputDecoration(
                  labelText: 'Course Name',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16.0),
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
