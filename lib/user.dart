import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class Userr {
  final String id;
  String name;
  String photoUrl;
  String university;
  String courseName;
  String yearOfStudy;

  Userr({required this.id, required this.name, required this.photoUrl, required this.university, required this.yearOfStudy, required this.courseName});
}